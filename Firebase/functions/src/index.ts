/**
 * ProteinChef Cloud Functions.
 *
 * Four Firestore triggers — each writes an in-app notification doc under
 * users/{uid}/notifications and sends an APNs push via FCM if the recipient
 * has a registered device token.
 *
 *  1. onFriendRequestCreated  — users/{uid}/friendRequests/{fromUid}
 *  2. onFriendAccepted        — users/{uid}/friends/{friendUid}
 *  3. onFeedPostCreated       — feedPosts/{postId} (fans out to author's friends)
 *  4. onFeedLikeCreated       — feedPosts/{postId}/likes/{likerUid}
 *  5. onFeedCommentCreated    — feedPosts/{postId}/comments/{commentId}
 *
 * Requires Firebase Blaze plan (Cloud Functions are not in the free tier) and
 * an APNs key uploaded in Firebase Console → Cloud Messaging → Apple app config.
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging, TokenMessage} from "firebase-admin/messaging";
import {logger} from "firebase-functions";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

type NotificationKind =
  | "friendRequest"
  | "friendAccepted"
  | "newFeedPost"
  | "feedLike"
  | "feedComment";

interface NotificationPayload {
  kind: NotificationKind;
  title: string;
  body: string;
  actorUid: string;
  actorHandle: string;
  actorDisplayName: string;
  actorPhotoURL?: string | null;
  targetId?: string | null;
}

/**
 * Writes a notification doc and — if the recipient has an fcmToken — sends a push.
 * Stale tokens are pruned automatically on unregistered errors.
 */
async function deliver(
  recipientUid: string,
  payload: NotificationPayload,
): Promise<void> {
  const notifId = db.collection("_").doc().id; // random id
  const notifRef = db
    .collection("users").doc(recipientUid)
    .collection("notifications").doc(notifId);

  await notifRef.set({
    id: notifId,
    kind: payload.kind,
    title: payload.title,
    body: payload.body,
    actorUid: payload.actorUid,
    actorHandle: payload.actorHandle,
    actorDisplayName: payload.actorDisplayName,
    actorPhotoURL: payload.actorPhotoURL ?? null,
    targetId: payload.targetId ?? null,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  const userSnap = await db.collection("users").doc(recipientUid).get();
  const token = userSnap.get("fcmToken") as string | undefined;
  if (!token) return;

  const message: TokenMessage = {
    token,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      kind: payload.kind,
      actorUid: payload.actorUid,
      targetId: payload.targetId ?? "",
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
          "mutable-content": 1,
        },
      },
    },
  };

  try {
    await messaging.send(message);
  } catch (err: unknown) {
    const code = (err as {code?: string})?.code ?? "";
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      await db.collection("users").doc(recipientUid).update({fcmToken: null});
    } else {
      logger.warn("FCM send failed", {recipientUid, code, err});
    }
  }
}

// ---------------------------------------------------------------------------
// 1. Friend request received
// ---------------------------------------------------------------------------

export const onFriendRequestCreated = onDocumentCreated(
  "users/{uid}/friendRequests/{fromUid}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    await deliver(event.params.uid, {
      kind: "friendRequest",
      title: "New friend request",
      body: `${data.fromDisplayName} (@${data.fromHandle}) wants to be friends.`,
      actorUid: data.id ?? event.params.fromUid,
      actorHandle: data.fromHandle ?? "",
      actorDisplayName: data.fromDisplayName ?? "",
      actorPhotoURL: data.fromPhotoURL ?? null,
      targetId: event.params.fromUid,
    });
  },
);

// ---------------------------------------------------------------------------
// 2. Friendship established (notify the original requester)
// ---------------------------------------------------------------------------

export const onFriendAccepted = onDocumentCreated(
  "users/{uid}/friends/{friendUid}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const recipient = event.params.uid;
    const actor = event.params.friendUid;

    // Only fire once per new friendship: the first side created is the original
    // requester's doc (they write into their own collection after the target
    // party creates the reciprocal doc). Skip if the actor wasn't the accepting side.
    // Heuristic: check if a corresponding sentRequest was cleared — if it was,
    // this is the notification-worthy side.
    const sent = await db.collection("users").doc(recipient)
      .collection("sentRequests").doc(actor).get();
    if (sent.exists) return; // request still pending on our side — other doc won't trigger yet

    await deliver(recipient, {
      kind: "friendAccepted",
      title: "You're now friends",
      body: `${data.friendDisplayName} (@${data.friendHandle}) accepted your request.`,
      actorUid: actor,
      actorHandle: data.friendHandle ?? "",
      actorDisplayName: data.friendDisplayName ?? "",
      actorPhotoURL: data.friendPhotoURL ?? null,
      targetId: actor,
    });
  },
);

// ---------------------------------------------------------------------------
// 3. New feed post — fan out to the author's friends
// ---------------------------------------------------------------------------

export const onFeedPostCreated = onDocumentCreated(
  "feedPosts/{postId}",
  async (event) => {
    const post = event.data?.data();
    if (!post) return;
    const authorUid = post.authorUid as string;

    const friendsSnap = await db.collection("users").doc(authorUid)
      .collection("friends").get();

    const recipeTitle = post.recipe?.title ?? "a new recipe";
    const tasks = friendsSnap.docs.map((doc) =>
      deliver(doc.id, {
        kind: "newFeedPost",
        title: `${post.authorDisplayName} shared a recipe`,
        body: recipeTitle,
        actorUid: authorUid,
        actorHandle: post.authorHandle ?? "",
        actorDisplayName: post.authorDisplayName ?? "",
        actorPhotoURL: post.authorPhotoURL ?? null,
        targetId: event.params.postId,
      })
    );

    await Promise.allSettled(tasks);
  },
);

// ---------------------------------------------------------------------------
// 4. Feed post liked — notify the post author
// ---------------------------------------------------------------------------

export const onFeedLikeCreated = onDocumentCreated(
  "feedPosts/{postId}/likes/{likerUid}",
  async (event) => {
    const postId = event.params.postId;
    const likerUid = event.params.likerUid;

    const postSnap = await db.collection("feedPosts").doc(postId).get();
    const post = postSnap.data();
    if (!post) return;
    if (post.authorUid === likerUid) return; // don't notify self-likes

    const likerSnap = await db.collection("users").doc(likerUid).get();
    const liker = likerSnap.data();
    if (!liker) return;

    await deliver(post.authorUid, {
      kind: "feedLike",
      title: `${liker.displayName ?? "Someone"} liked your recipe`,
      body: post.recipe?.title ?? "",
      actorUid: likerUid,
      actorHandle: liker.handle ?? "",
      actorDisplayName: liker.displayName ?? "",
      actorPhotoURL: liker.photoURL ?? null,
      targetId: postId,
    });
  },
);

// ---------------------------------------------------------------------------
// 5. Feed post comment — notify the post author
// ---------------------------------------------------------------------------

export const onFeedCommentCreated = onDocumentCreated(
  "feedPosts/{postId}/comments/{commentId}",
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;
    const postId = event.params.postId;

    const postSnap = await db.collection("feedPosts").doc(postId).get();
    const post = postSnap.data();
    if (!post) return;
    if (post.authorUid === comment.authorUid) return; // don't notify self-comments

    await deliver(post.authorUid, {
      kind: "feedComment",
      title: `${comment.authorDisplayName} commented on your recipe`,
      body: truncate(comment.text ?? "", 120),
      actorUid: comment.authorUid,
      actorHandle: comment.authorHandle ?? "",
      actorDisplayName: comment.authorDisplayName ?? "",
      actorPhotoURL: comment.authorPhotoURL ?? null,
      targetId: postId,
    });
  },
);

function truncate(s: string, max: number): string {
  if (s.length <= max) return s;
  return s.slice(0, max - 1) + "…";
}
