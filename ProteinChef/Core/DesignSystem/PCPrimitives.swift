import SwiftUI

// MARK: - Eyebrow (mono uppercase caption above a screen title)

struct PCEyebrow: View {
    let text: String
    var color: Color = Theme.Colors.ink3
    var body: some View {
        Text(text.uppercased())
            .font(Theme.Fonts.mono(10))
            .tracking(1.0)
            .foregroundStyle(color)
    }
}

// MARK: - App bar (large display title + optional eyebrow + trailing icon buttons)

struct PCAppBar<Trailing: View>: View {
    let title: String
    let eyebrow: String?
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, eyebrow: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.eyebrow = eyebrow
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                if let eyebrow {
                    PCEyebrow(text: eyebrow)
                }
                Text(title)
                    .font(Theme.Fonts.screenTitle)
                    .tracking(-1.2)
                    .foregroundStyle(Theme.Colors.ink)
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.xs)
        .padding(.bottom, Theme.Spacing.m)
    }
}

// MARK: - Icon button (40pt circle, paper or ink variant)

struct PCIconButton: View {
    enum Variant { case paper, ink }
    let systemName: String
    var variant: Variant = .paper
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 40, height: 40)
                .foregroundStyle(variant == .paper ? Theme.Colors.ink : Theme.Colors.paper)
                .background(variant == .paper ? Theme.Colors.paper : Theme.Colors.ink)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Theme.Colors.line,
                                    lineWidth: variant == .paper ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card shell (paper / ink / indigo variants, 22pt radius by default)

struct PCCard<Content: View>: View {
    enum Style { case paper, ink, indigo, flat }
    let style: Style
    let radius: CGFloat
    let padding: CGFloat
    @ViewBuilder var content: () -> Content

    init(style: Style = .paper,
         radius: CGFloat = Theme.Radius.l,
         padding: CGFloat = 20,
         @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.radius = radius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(borderColor, lineWidth: style == .flat ? 0 : 1)
            )
    }

    private var background: Color {
        switch style {
        case .paper:  Theme.Colors.paper
        case .ink:    Theme.Colors.ink
        case .indigo: Theme.Colors.indigo
        case .flat:   .clear
        }
    }
    private var foreground: Color {
        switch style {
        case .paper:  Theme.Colors.ink
        case .ink:    Theme.Colors.paper
        case .indigo: .white
        case .flat:   Theme.Colors.ink
        }
    }
    private var borderColor: Color {
        switch style {
        case .paper:  Theme.Colors.line
        case .ink:    Theme.Colors.ink
        case .indigo: Theme.Colors.indigo
        case .flat:   .clear
        }
    }
}

// MARK: - Chip (pill, 6 variants)

struct PCChip: View {
    enum Style { case neutral, active, lime, indigo, ghost, outlined }
    let text: String
    var style: Style = .neutral
    var systemImage: String?
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { label }
                    .buttonStyle(.plain)
            } else {
                label
            }
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(Theme.Fonts.ui(12, weight: fontWeight))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(background)
        .foregroundStyle(foreground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(borderColor, lineWidth: style == .outlined || style == .neutral ? 1 : 0))
    }

    private var background: Color {
        switch style {
        case .neutral:  Theme.Colors.paper
        case .active:   Theme.Colors.ink
        case .lime:     Theme.Colors.lime
        case .indigo:   Theme.Colors.indigo
        case .ghost:    .clear
        case .outlined: .clear
        }
    }
    private var foreground: Color {
        switch style {
        case .neutral:  Theme.Colors.ink2
        case .active:   Theme.Colors.paper
        case .lime:     Theme.Colors.limeInk
        case .indigo:   .white
        case .ghost:    Theme.Colors.ink2
        case .outlined: Theme.Colors.ink2
        }
    }
    private var borderColor: Color {
        switch style {
        case .neutral:  Theme.Colors.line
        case .outlined: Theme.Colors.line2
        default:        .clear
        }
    }
    private var fontWeight: Font.Weight {
        switch style {
        case .lime, .indigo, .active: .semibold
        default: .medium
        }
    }
}

// MARK: - Horizontal macro bar

struct PCMacroBar: View {
    let current: Double
    let goal: Double
    var tint: Color
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.ink.opacity(0.07))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, current / max(goal, 1))) * geo.size.width)
                    .animation(.easeOut(duration: 0.6), value: current)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Primary button (capsule)

struct PCButton: View {
    enum Style { case ink, indigo, lime, ghost }
    let title: String
    var systemImage: String?
    var style: Style = .indigo
    var size: Size = .regular
    var action: () -> Void

    enum Size { case regular, small }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(Theme.Fonts.ui(size == .small ? 13 : 15, weight: .semibold))
            }
            .padding(.horizontal, size == .small ? 14 : 18)
            .padding(.vertical,   size == .small ? 10 : 14)
            .frame(maxWidth: .infinity)
            .background(background)
            .foregroundStyle(foreground)
            .overlay(Capsule().stroke(style == .ghost ? Theme.Colors.line : .clear, lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch style {
        case .ink:    Theme.Colors.ink
        case .indigo: Theme.Colors.indigo
        case .lime:   Theme.Colors.lime
        case .ghost:  .clear
        }
    }
    private var foreground: Color {
        switch style {
        case .ink, .indigo: .white
        case .lime:         Theme.Colors.limeInk
        case .ghost:        Theme.Colors.ink
        }
    }
}

// MARK: - Stat tile (3-up grid on Train + Settings)

struct PCStatTile: View {
    let value: String
    let label: String
    var valueColor: Color = Theme.Colors.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Theme.Fonts.display(28))
                .tracking(-0.5)
                .foregroundStyle(valueColor)
            PCEyebrow(text: label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.Colors.paper)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }
}

// MARK: - Placeholder image (diagonal-stripe with mono label)

struct PCPlaceholder: View {
    let label: String
    var dark: Bool = false
    var height: CGFloat? = nil

    var body: some View {
        ZStack {
            (dark
             ? LinearGradient(colors: [Color(hex: 0x151820), Color(hex: 0x0C0E13)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
             : LinearGradient(colors: [Theme.Colors.ink.opacity(0.05), Theme.Colors.ink.opacity(0.09)],
                              startPoint: .topLeading, endPoint: .bottomTrailing))

            Canvas { ctx, size in
                let stripeColor = dark
                    ? Color.white.opacity(0.04)
                    : Theme.Colors.ink.opacity(0.04)
                ctx.stroke(
                    Path { p in
                        for x in stride(from: -size.height, through: size.width, by: 11) {
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                        }
                    },
                    with: .color(stripeColor),
                    lineWidth: 1
                )
            }

            Text(label.uppercased())
                .font(Theme.Fonts.mono(10))
                .tracking(1.2)
                .foregroundStyle(dark ? Color(white: 1, opacity: 0.55) : Theme.Colors.ink3)
                .multilineTextAlignment(.center)
                .padding(12)
        }
        .frame(height: height)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.l)
                .stroke(dark ? Color.white.opacity(0.08) : Theme.Colors.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
    }
}

// MARK: - Asynchronous cover image that falls back to a PCPlaceholder

struct PCCoverImage: View {
    let url: URL?
    let placeholderLabel: String
    var height: CGFloat? = nil

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    PCPlaceholder(label: placeholderLabel, height: height)
                }
            }
            .frame(height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
        } else {
            PCPlaceholder(label: placeholderLabel, height: height)
        }
    }
}

// MARK: - Segmented control (3-up, mono uppercase labels)

struct PCSegmented<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(Value, String)]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.0) { value, label in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { selection = value }
                } label: {
                    Text(label.uppercased())
                        .font(Theme.Fonts.mono(10))
                        .tracking(0.8)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selection == value ? Theme.Colors.ink : Theme.Colors.ink3)
                        .background(selection == value ? Theme.Colors.paper : .clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.Colors.ink.opacity(0.06))
        .clipShape(Capsule())
    }
}

// MARK: - Progress bar (onboarding)

struct PCSegmentProgress: View {
    let total: Int
    let current: Int        // 1-based

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { idx in
                Capsule()
                    .fill(idx < current ? Theme.Colors.ink : Theme.Colors.line2)
                    .frame(height: 4)
            }
        }
    }
}
