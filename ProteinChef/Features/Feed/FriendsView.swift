import SwiftUI

struct FriendsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.userProfile) private var profile
    @Environment(\.dismiss) private var dismiss

    @State private var friends: [Friendship] = []
    @State private var requests: [FriendRequest] = []
    @State private var sent: [SentRequest] = []
    @State private var query: String = ""
    @State private var searchResult: UserProfile?
    @State private var searchRelation: FriendRelation?
    @State private var isSearching = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            List {
                searchSection

                if !requests.isEmpty {
                    Section("Requests") {
                        ForEach(requests) { req in
                            requestRow(req)
                        }
                    }
                }

                Section("Friends") {
                    if friends.isEmpty {
                        Text("No friends yet — look up a handle above.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(friends) { f in
                            friendRow(f)
                        }
                        .onDelete(perform: unfriend)
                    }
                }

                if !sent.isEmpty {
                    Section("Sent requests") {
                        ForEach(sent) { s in
                            sentRow(s)
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task(id: env.auth.currentUid ?? "") { await subscribe() }
            .alert("Error", isPresented: .constant(errorText != nil)) {
                Button("OK") { errorText = nil }
            } message: { Text(errorText ?? "") }
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        Section("Add friend by handle") {
            HStack {
                TextField("e.g. ahmed", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    Task { await lookup() }
                } label: {
                    if isSearching {
                        ProgressView()
                    } else {
                        Text("Find").fontWeight(.semibold)
                    }
                }
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
            }
            if let found = searchResult, let relation = searchRelation {
                searchResultRow(found: found, relation: relation)
            }
        }
    }

    @ViewBuilder
    private func searchResultRow(found: UserProfile, relation: FriendRelation) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            avatar(found.photoURL, initial: String(found.displayName.prefix(1)))
            VStack(alignment: .leading, spacing: 2) {
                Text(found.displayName).font(.subheadline.bold())
                Text("@\(found.handle)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            relationButton(found: found, relation: relation)
        }
    }

    @ViewBuilder
    private func relationButton(found: UserProfile, relation: FriendRelation) -> some View {
        switch relation {
        case .self_:
            Text("That's you").font(.caption).foregroundStyle(.tertiary)
        case .none:
            Button("Send request") {
                Task { await sendRequest(to: found) }
            }
            .buttonStyle(.borderedProminent)
            .font(.caption)
        case .outgoingPending:
            Text("Pending…").font(.caption).foregroundStyle(.secondary)
        case .incomingPending:
            Button("Accept") {
                Task { await accept(fromUid: found.id) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.protein)
            .font(.caption)
        case .friends:
            Label("Friends", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Theme.Colors.protein)
        }
    }

    // MARK: - Rows

    private func requestRow(_ req: FriendRequest) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            avatar(req.fromPhotoURL, initial: String(req.fromDisplayName.prefix(1)))
            VStack(alignment: .leading, spacing: 2) {
                Text(req.fromDisplayName).font(.subheadline.bold())
                Text("@\(req.fromHandle)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Button("Accept") { Task { await accept(fromUid: req.id) } }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Colors.protein)
                    .font(.caption)
                Button("Decline") { Task { await decline(fromUid: req.id) } }
                    .buttonStyle(.bordered)
                    .font(.caption)
            }
        }
    }

    private func friendRow(_ f: Friendship) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            avatar(f.friendPhotoURL, initial: String(f.friendDisplayName.prefix(1)))
            VStack(alignment: .leading, spacing: 2) {
                Text(f.friendDisplayName).font(.subheadline)
                Text("@\(f.friendHandle)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func sentRow(_ s: SentRequest) -> some View {
        HStack {
            Text("@\(s.toHandle)").font(.subheadline)
            Spacer()
            Text("Pending").font(.caption).foregroundStyle(.secondary)
            Button {
                Task { await cancel(toUid: s.id) }
            } label: {
                Image(systemName: "xmark.circle").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func avatar(_ url: URL?, initial: String) -> some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(Text(initial).font(.caption))
        }
    }

    // MARK: - Actions

    private func subscribe() async {
        guard let uid = env.auth.currentUid else { return }
        async let a: () = subscribeFriends(uid: uid)
        async let b: () = subscribeRequests(uid: uid)
        async let c: () = subscribeSent(uid: uid)
        _ = await (a, b, c)
    }

    private func subscribeFriends(uid: String) async {
        do {
            for try await list in env.friends.listFriendsStream(uid: uid) { friends = list }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func subscribeRequests(uid: String) async {
        do {
            for try await list in env.friends.listIncomingRequestsStream(uid: uid) { requests = list }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func subscribeSent(uid: String) async {
        do {
            for try await list in env.friends.listSentRequestsStream(uid: uid) { sent = list }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func lookup() async {
        isSearching = true
        defer { isSearching = false }
        searchResult = nil
        searchRelation = nil
        do {
            guard let me = env.auth.currentUid,
                  let found = try await env.friends.lookupByHandle(query) else {
                errorText = "No user found with that handle."
                return
            }
            let relation = try await env.friends.relation(meUid: me, otherUid: found.id)
            searchResult = found
            searchRelation = relation
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func sendRequest(to other: UserProfile) async {
        guard let me = profile else { return }
        do {
            try await env.friends.sendRequest(me: me, toUid: other.id, toHandle: other.handle)
            searchRelation = .outgoingPending
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func accept(fromUid: String) async {
        guard let me = profile else { return }
        do {
            try await env.friends.acceptRequest(me: me, fromUid: fromUid)
            if searchResult?.id == fromUid { searchRelation = .friends }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func decline(fromUid: String) async {
        guard let meUid = env.auth.currentUid else { return }
        do {
            try await env.friends.declineRequest(meUid: meUid, fromUid: fromUid)
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func cancel(toUid: String) async {
        guard let meUid = env.auth.currentUid else { return }
        do {
            try await env.friends.cancelSentRequest(meUid: meUid, toUid: toUid)
            if searchResult?.id == toUid { searchRelation = .none }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func unfriend(at offsets: IndexSet) {
        guard let meUid = env.auth.currentUid else { return }
        let toRemove = offsets.map { friends[$0].id }
        Task {
            for uid in toRemove {
                try? await env.friends.unfriend(meUid: meUid, friendUid: uid)
            }
        }
    }
}
