import SwiftUI
import UIKit
import SwiftData

// MARK: - Paleta
extension Color {
    static let mint = Color(red: 0.663, green: 0.804, blue: 0.749)
    static let mintDark = Color(red: 0.435, green: 0.627, blue: 0.537)
    static let mintDeep = Color(red: 0.243, green: 0.431, blue: 0.345)
    static let cream = Color(red: 0.969, green: 0.980, blue: 0.973)
    static let ink = Color(red: 0.180, green: 0.231, blue: 0.212)
    static let softGray = Color(red: 0.541, green: 0.588, blue: 0.561)
    static let warnColor = Color(red: 0.788, green: 0.482, blue: 0.388)
}

// MARK: - Transición suave entre pantallas
struct FlashTransition: ViewModifier {
    func body(content: Content) -> some View {
        content
            .transition(
                .asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.98)).animation(.easeOut(duration: 0.45)),
                    removal: .opacity.animation(.easeIn(duration: 0.25))
                )
            )
    }
}

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - Contenedor principal
struct ContentView: View {
    @Query(sort: \PauseAttempt.timestamp, order: .reverse) private var attempts: [PauseAttempt]
    @Query(sort: \FallLog.date, order: .reverse) private var fallLogs: [FallLog]
    @State private var screen = "welcome"
    @State private var userMessage = ""
    @State private var timerDuration = 120 // 2 minutos por defecto
    @State private var showFirmeApp = true

    var body: some View {
        ZStack {
            switch screen {
            case "welcome":
                WelcomeView(screen: $screen).modifier(FlashTransition())
            case "password":
                PasswordSetupView(screen: $screen).modifier(FlashTransition())
            case "message":
                MessageSetupView(screen: $screen, userMessage: $userMessage).modifier(FlashTransition())
            case "sites":
                SitesSetupView(screen: $screen).modifier(FlashTransition())
            case "home":
                HomeView(screen: $screen, userMessage: userMessage, timerDuration: timerDuration, attempts: attempts, fallLogs: fallLogs).modifier(FlashTransition())
            case "timer":
                TimerView(screen: $screen, userMessage: userMessage, timerDuration: timerDuration).modifier(FlashTransition())
            case "metrics":
                MetricsView(screen: $screen, attempts: attempts, fallLogs: fallLogs).modifier(FlashTransition())
            case "settings":
                SettingsView(screen: $screen, userMessage: $userMessage, timerDuration: $timerDuration).modifier(FlashTransition())
            case "dns":
                DNSSetupView(screen: $screen).modifier(FlashTransition())
            default:
                WelcomeView(screen: $screen)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: screen)
        .preferredColorScheme(.light)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.startLocation.x < 30 && value.translation.width > 80 {
                        goBack()
                    }
                }
        )
        .onOpenURL { url in
            if url.scheme == "firme" && url.host == "pausa" {
                screen = "timer"
            }
        }
    }

    func goBack() {
        switch screen {
        case "password": screen = "welcome"
        case "message": screen = "password"
        case "sites": screen = "message"
        case "timer", "metrics", "settings": screen = "home"
        default: break
        }
    }
}


// MARK: - Botón de regresar
struct BackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
        }
    }
}

// MARK: - Campo de contraseña con ojito
struct PasswordFieldWithEye: View {
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<PasswordSetupView.Field?>.Binding
    let fieldTag: PasswordSetupView.Field
    var submitLabel: SubmitLabel = .next
    var onSubmitAction: () -> Void = {}
    @State private var isVisible = false

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .foregroundColor(.ink)
            .focused(focus, equals: fieldTag)
            .submitLabel(submitLabel)
            .onSubmit(onSubmitAction)

            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.softGray)
            }
        }
        .padding(13)
        .background(Color.white)
        .cornerRadius(11)
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.mintDark.opacity(0.2), lineWidth: 1.5))
    }
}

// MARK: - Pantalla 1: Bienvenida
struct WelcomeView: View {
    @Binding var screen: String
    @State private var floatUp = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.mintDeep, .mintDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("🌱")
                    .font(.system(size: 52))
                    .offset(y: floatUp ? -8 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                            floatUp = true
                        }
                    }

                Text("Firme")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)

                Text("Un espacio simple para pausar, reflexionar, y ver tu propio avance.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    featureRow(icon: "⏸️", title: "Pausa de unos minutos", desc: "Tiempo para que la urgencia baje antes de decidir")
                    featureRow(icon: "📈", title: "Tu progreso, claro", desc: "Números simples que muestran que sí estás avanzando")
                    featureRow(icon: "🔐", title: "Tú tienes el control", desc: "Nadie más ve esto ni lo puede tocar sin tu clave")
                }
                .padding(18)
                .background(Color.white.opacity(0.12))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))

                Button(action: { screen = "password" }) {
                    Text("Empezar →")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.mintDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding(24)
        }
    }

    func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Text(icon).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(desc).font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
    }
}

// MARK: - Pantalla 2: Contraseña
struct PasswordSetupView: View {
    @Binding var screen: String
    @Environment(\.modelContext) private var modelContext
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var errorMsg = ""
    
    enum Field { case pass, confirm }
    @FocusState private var focusedField: Field?
    
    var strength: Double {
        var score = 0.0
        if password.count >= 8 { score += 0.2 }
        if password.count >= 12 { score += 0.2 }
        if password.contains(where: { $0.isNumber }) { score += 0.2 }
        if password.contains(where: { $0.isUppercase }) { score += 0.2 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 0.2 }
        return min(score, 1.0)
    }
    
    var strengthColor: Color {
        if password.isEmpty { return Color(red: 0.83, green: 0.88, blue: 0.85) }
        if strength <= 0.4 { return .warnColor }
        if strength <= 0.6 { return Color(red: 0.85, green: 0.64, blue: 0.25) }
        return .mintDark
    }
    
    var strengthLabel: String {
        if password.isEmpty { return "Empieza a escribir…" }
        if strength <= 0.4 { return "Débil — muy fácil de adivinar" }
        if strength <= 0.6 { return "Aceptable — puede mejorar" }
        return "Fuerte 👍"
    }
    
    var isValid: Bool {
        password.count >= 8 && password.contains(where: { $0.isNumber }) && password.contains(where: { $0.isLetter })
    }
    
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    BackButton(action: { screen = "welcome" })
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Crea tu clave")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Que sea difícil de adivinar — hasta para ti en un mal momento")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(colors: [Color(red: 0.498, green: 0.702, blue: 0.612), Color(red: 0.353, green: 0.557, blue: 0.467)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea(edges: .top)
            )
            .frame(maxHeight: .infinity, alignment: .top)
            
            VStack {
                Spacer().frame(height: 130)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Evita \"1234\" o tu cumpleaños. Una clave más larga y rara es tu mejor freno cuando la urgencia te empuje a desactivar todo. Mínimo 8 caracteres, con letras y números.")
                            .font(.system(size: 13.5))
                            .foregroundColor(.ink)
                            .padding(14)
                            .background(Color(red: 0.933, green: 0.965, blue: 0.945))
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Clave").font(.system(size: 13.5, weight: .semibold)).foregroundColor(.ink)
                            
                            PasswordFieldWithEye(
                                placeholder: "Mínimo 8 caracteres",
                                text: $password,
                                focus: $focusedField,
                                fieldTag: .pass,
                                submitLabel: .next,
                                onSubmitAction: { focusedField = .confirm }
                            )
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.83, green: 0.88, blue: 0.85))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(strengthColor)
                                        .frame(width: geo.size.width * strength)
                                        .animation(.easeInOut(duration: 0.35), value: strength)
                                }
                            }
                            .frame(height: 5)
                            
                            Text(strengthLabel)
                                .font(.system(size: 12))
                                .foregroundColor(.softGray)
                                .animation(.easeInOut(duration: 0.2), value: strengthLabel)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirmar clave").font(.system(size: 13.5, weight: .semibold)).foregroundColor(.ink)
                            
                            PasswordFieldWithEye(
                                placeholder: "Repítela",
                                text: $passwordConfirm,
                                focus: $focusedField,
                                fieldTag: .confirm,
                                submitLabel: .done,
                                onSubmitAction: { validate() }
                            )
                            
                            if !errorMsg.isEmpty {
                                Text(errorMsg).font(.system(size: 12.5)).foregroundColor(.warnColor)
                            }
                        }
                        
                        Button(action: validate) {
                            Text("Siguiente →")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isValid ? Color.mintDeep : Color.gray.opacity(0.4))
                                .cornerRadius(10)
                        }
                        .disabled(!isValid)
                    }
                    .padding(22)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onTapGesture { dismissKeyboard() }
    }
    
    func validate() {
        guard isValid else { return }
        if password != passwordConfirm {
            errorMsg = "No coinciden"
            return
        }
        errorMsg = ""
        let profile = UserProfile(passwordHash: hashPassword(password), userMessage: "")
        modelContext.insert(profile)
        try? modelContext.save()
        screen = "message"
    }
}

// MARK: - Pantalla 3: Tu razón
struct MessageSetupView: View {
    @Binding var screen: String
    @Binding var userMessage: String
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @FocusState private var isFocused: Bool

    let suggestions = [
        "Mi familia merece mi presencia real, no una a medias.",
        "No quiero esconderle esto a quien amo.",
        "Quiero ser el padre que mis hijos merecen.",
        "Mi futura esposa merece un hombre íntegro.",
        "Esto me aleja de las personas que más amo.",
        "Hoy elijo a mi familia, no esto."
    ]

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackButton(action: { screen = "password" })
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu razón").font(.system(size: 21, weight: .semibold)).foregroundColor(.white)
                    Text("Esto se te va a mostrar cada vez que pauses").font(.system(size: 13)).foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(colors: [Color(red: 0.498, green: 0.702, blue: 0.612), Color(red: 0.353, green: 0.557, blue: 0.467)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea(edges: .top)
            )
            .frame(maxHeight: .infinity, alignment: .top)

            VStack {
                Spacer().frame(height: 130)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Piensa en quién te importa, no solo en \"portarte bien\". Algunas ideas:")
                            .font(.system(size: 13.5))
                            .foregroundColor(.ink)
                            .padding(14)
                            .background(Color(red: 0.933, green: 0.965, blue: 0.945))
                            .cornerRadius(12)

                        FlowLayout(spacing: 8) {
                            ForEach(suggestions, id: \.self) { s in
                                Button(action: { userMessage = s }) {
                                    Text(s)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.mintDeep)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.85, green: 0.89, blue: 0.87), lineWidth: 1))
                                }
                            }
                        }

                        TextEditor(text: $userMessage)
                            .foregroundColor(.ink)
                            .scrollContentBackground(.hidden)
                            .frame(height: 90)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(11)
                            .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.mintDark.opacity(0.2), lineWidth: 1.5))
                            .focused($isFocused)
                            .onChange(of: userMessage) { _, newValue in
                                if newValue.count > 100 { userMessage = String(newValue.prefix(100)) }
                            }

                        Text("\(100 - userMessage.count) caracteres restantes")
                            .font(.system(size: 12))
                            .foregroundColor(.softGray)

                        Button(action: {
                            if let profile = profiles.first {
                                profile.userMessage = userMessage
                                try? modelContext.save()
                            }
                            screen = "sites"
                        }) {
                            Text("Siguiente →")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(userMessage.count >= 5 ? Color.mintDeep : Color.gray.opacity(0.4))
                                .cornerRadius(10)
                        }
                        .disabled(userMessage.count < 5)
                    }
                    .padding(22)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onTapGesture { dismissKeyboard() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { isFocused = false }
            }
        }
    }
}

// MARK: - Pantalla 4: Sitios protegidos
struct SitesSetupView: View {
    @Binding var screen: String
    @State private var showAll = false

    let exampleSites = ["pornhub.com", "xvideos.com", "xnxx.com", "xhamster.com", "redtube.com", "youporn.com"]

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackButton(action: { screen = "message" })
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sitios protegidos").font(.system(size: 21, weight: .semibold)).foregroundColor(.white)
                    Text("Ya están activos, no puedes quitarlos").font(.system(size: 13)).foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(colors: [Color(red: 0.498, green: 0.702, blue: 0.612), Color(red: 0.353, green: 0.557, blue: 0.467)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea(edges: .top)
            )
            .frame(maxHeight: .infinity, alignment: .top)

            VStack {
                Spacer().frame(height: 130)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Estos sitios usan una lista pública actualizada regularmente. Podrás agregar más después.")
                            .font(.system(size: 13.5))
                            .foregroundColor(.ink)
                            .padding(14)
                            .background(Color(red: 0.933, green: 0.965, blue: 0.945))
                            .cornerRadius(12)

                        VStack(spacing: 4) {
                            Text("214 mil+")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            Text("sitios bloqueados automáticamente")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(22)
                        .background(LinearGradient(colors: [.mintDark, .mintDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(16)
                        .shadow(color: .mintDeep.opacity(0.25), radius: 10, y: 5)

                        ForEach(showAll ? exampleSites : Array(exampleSites.prefix(4)), id: \.self) { site in
                            HStack(spacing: 10) {
                                Text("🔒")
                                Text(site).font(.system(size: 13.5)).foregroundColor(.ink)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.75))
                            .cornerRadius(12)
                        }

                        Button(action: { showAll.toggle() }) {
                            Text(showAll ? "Ver menos" : "Ver ejemplos →")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundColor(.mintDark)
                        }

                        Button(action: { screen = "dns" }) {
                            Text("Listo →")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.mintDeep)
                                .cornerRadius(10)
                        }
                        .padding(.top, 6)
                    }
                    .padding(22)
                }
            }
        }
    }
}

// MARK: - Pantalla de activación de bloqueo real (NextDNS)
struct DNSSetupView: View {
    @Binding var screen: String

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackButton(action: { screen = "sites" })
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Un paso más").font(.system(size: 21, weight: .semibold)).foregroundColor(.white)
                    Text("Esto es lo que bloquea de verdad").font(.system(size: 13)).foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(colors: [Color(red: 0.498, green: 0.702, blue: 0.612), Color(red: 0.353, green: 0.557, blue: 0.467)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea(edges: .top)
            )
            .frame(maxHeight: .infinity, alignment: .top)

            VStack {
                Spacer().frame(height: 130)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Firme te acompaña con pausas y seguimiento. Pero para bloquear sitios de verdad — en cualquier navegador, no solo Safari — necesitas activar NextDNS, un servicio externo gratuito y de confianza.")
                            .font(.system(size: 13.5))
                            .foregroundColor(.ink)
                            .padding(14)
                            .background(Color(red: 0.933, green: 0.965, blue: 0.945))
                            .cornerRadius(12)

                        stepRow(number: "1", text: "Descarga la app NextDNS (gratis, App Store)")
                        stepRow(number: "2", text: "Crea una cuenta con tu correo")
                        stepRow(number: "3", text: "Activa la categoría \"Porn\" en Privacidad")
                        stepRow(number: "4", text: "Instala el perfil cuando te lo pida")
                        stepRow(number: "5", text: "Pon un PIN en NextDNS para protegerlo")

                        Button(action: {
                            if let url = URL(string: "https://apps.apple.com/us/app/nextdns/id1463342498") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Abrir NextDNS en la App Store")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.mintDeep)
                            .cornerRadius(10)
                        }

                        Text("NextDNS es un servicio independiente, no afiliado a Firme. Lo recomendamos porque funciona de verdad y respeta tu privacidad.")
                            .font(.system(size: 11))
                            .foregroundColor(.softGray)
                            .italic()

                        Button(action: { screen = "home" }) {
                            Text("Ya lo activé, continuar →")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.mintDeep)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mintDark.opacity(0.3), lineWidth: 1.2))
                        }

                        Button(action: { screen = "home" }) {
                            Text("Lo haré después")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.softGray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(22)
                }
            }
        }
    }

    func stepRow(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Color.mintDark)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13.5))
                .foregroundColor(.ink)

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.75))
        .cornerRadius(12)
    }
}

// MARK: - Home real
struct HomeView: View {
    @Binding var screen: String
    let userMessage: String
    let timerDuration: Int
    let attempts: [PauseAttempt]
    let fallLogs: [FallLog]
    @Environment(\.modelContext) private var modelContext
    @State private var justLoggedFall = false

    var attemptsToday: Int {
        attempts.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    var streakDays: Int {
        let calendar = Calendar.current
        guard let lastFall = fallLogs.first?.date else {
            // Nunca ha registrado una caida: cuenta desde que creo el perfil.
            // Por ahora, usa la fecha de la pausa mas antigua como referencia simple.
            guard let firstEver = attempts.last?.timestamp else { return 0 }
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstEver), to: calendar.startOfDay(for: Date())).day ?? 0
            return days
        }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastFall), to: calendar.startOfDay(for: Date())).day ?? 0
        return days
    }

    func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let isToday = Calendar.current.isDateInToday(date)
        return (isToday ? "Hoy · " : "") + formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Firme").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                    Text("Un día a la vez").font(.system(size: 13)).foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(colors: [Color(red: 0.498, green: 0.702, blue: 0.612), Color(red: 0.353, green: 0.557, blue: 0.467)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea(edges: .top)
                )

                ScrollView {
                    VStack(spacing: 22) {
                        HStack(spacing: 16) {
                            Text("🔥").font(.system(size: 38))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(streakDays) días").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                                Text("Tu racha más larga. Sigue así.").font(.system(size: 12.5)).foregroundColor(.white.opacity(0.9))
                            }
                            Spacer()
                        }
                        .padding(22)
                        .background(LinearGradient(colors: [.mintDark, .mintDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(18)
                        .shadow(color: .mintDeep.opacity(0.25), radius: 12, y: 6)

                        HStack(spacing: 12) {
                            statCard(number: "\(streakDays)", label: "días seguidos")
                            statCard(number: "\(attemptsToday)", label: "pausas hoy")
                        }

                        HStack(spacing: 10) {
                            Text("💭").font(.system(size: 18))
                            Text(userMessage.isEmpty ? "Mi familia merece mi presencia real." : userMessage)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.mintDeep)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.75))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mintDark.opacity(0.2), lineWidth: 1))

                        HStack(spacing: 10) {
                            actionButton(icon: "⏸️", label: "Pausar", primary: true) { screen = "timer" }
                            actionButton(icon: "📈", label: "Progreso", primary: false) { screen = "metrics" }
                            actionButton(icon: "⚙️", label: "Ajustes", primary: false) { screen = "settings" }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("💡 Lo que notamos").font(.system(size: 14, weight: .semibold)).foregroundColor(.ink)
                            insightCard("Tus pausas suelen pasar entre 10pm y 1am. Cargar el teléfono fuera del cuarto esas horas podría ayudarte.")
                            insightCard("Los domingos llevas 3 semanas seguidas en cero. Lo que hagas ese día está funcionando — repítelo.")
                        }
                       
                        
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Últimas pausas").font(.system(size: 14, weight: .semibold)).foregroundColor(.ink)
                            if attempts.isEmpty {
                                Text("Aún no hay pausas registradas.")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(.softGray)
                            } else {
                                ForEach(attempts.prefix(4)) { attempt in
                                    attemptRow(site: attempt.site, time: formatted(attempt.timestamp))
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    func statCard(number: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(number).font(.system(size: 28, weight: .bold)).foregroundColor(.mintDeep)
            Text(label).font(.system(size: 12.5)).foregroundColor(.softGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.75))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mintDark.opacity(0.2), lineWidth: 1))
    }

    func actionButton(icon: String, label: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(icon).font(.system(size: 22))
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(primary ? .white : .ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(primary ? AnyView(LinearGradient(colors: [.mintDark, .mintDeep], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyView(Color.white.opacity(0.75)))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(primary ? Color.clear : Color.mintDark.opacity(0.2), lineWidth: 1))
        }
    }

    func insightCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13.5))
            .foregroundColor(.ink)
            .lineSpacing(3)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.75))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mintDark.opacity(0.15), lineWidth: 1))
    }

    func attemptRow(site: String, time: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(site).font(.system(size: 13.5, weight: .semibold)).foregroundColor(.ink)
                Text(time).font(.system(size: 12)).foregroundColor(.softGray)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.75))
        .cornerRadius(12)
    }
}

// MARK: - Timer
struct TimerView: View {
    @Binding var screen: String
    let userMessage: String
    let timerDuration: Int
    @Environment(\.modelContext) private var modelContext

    @State private var timeLeft: Int = 0
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @State private var finished = false

    var duration: Int { timerDuration }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.298, green: 0.471, blue: 0.384), .mintDeep], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                Text("Antes de seguir \(Text("recuerda:").fontWeight(.bold))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.ink)

                Text("\u{201C}\(userMessage.isEmpty ? "Mi familia merece mi presencia real." : userMessage)\u{201D}")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.mintDeep)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                ZStack {
                    Circle()
                        .stroke(Color(red: 0.89, green: 0.925, blue: 0.905), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.mintDark, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: Double(duration)), value: progress)

                    Text(timeString)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.mintDeep)
                }
                .frame(width: 150, height: 150)

                Text(finished ? "Bien hecho. La urgencia baja con el tiempo." : "Respira. Esto va a pasar.")
                    .font(.system(size: 13.5))
                    .foregroundColor(.softGray)

                VStack(spacing: 10) {
                    Button(action: { if finished { screen = "home" } }) {
                        Text(finished ? "Ya pasó, sigo con mi día" : "Espera un momento…")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(finished ? Color.mintDark : Color.gray.opacity(0.4))
                            .cornerRadius(10)
                    }
                    .disabled(!finished)

                    Button(action: {
                        if let url = URL(string: "https://www.churchofjesuschrist.org/life/pornography?lang=spa") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Todavía lo siento, necesito ayuda")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.warnColor)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(26)
            .padding(24)
        }
        .onAppear {
                    startTimer()
                    let attempt = PauseAttempt(site: "Pausa manual")
                    modelContext.insert(attempt)
                    try? modelContext.save()
                }
        .onDisappear { timer?.invalidate() }
    }

    var timeString: String {
        let m = timeLeft / 60
        let s = timeLeft % 60
        return String(format: "%d:%02d", m, s)
    }

    func startTimer() {
        timeLeft = duration
        progress = 0
        finished = false
        withAnimation(.linear(duration: Double(duration))) {
            progress = 1.0
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                t.invalidate()
                finished = true
            }
        }
    }
}

// MARK: - Pantalla de Progreso
struct MetricsView: View {
    @Binding var screen: String
    let attempts: [PauseAttempt]
    let fallLogs: [FallLog]

    var streakDays: Int {
        let calendar = Calendar.current
        guard let lastFall = fallLogs.first?.date else {
            guard let firstEver = attempts.last?.timestamp else { return 0 }
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstEver), to: calendar.startOfDay(for: Date())).day ?? 0
            return days
        }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastFall), to: calendar.startOfDay(for: Date())).day ?? 0
        return days
    }

    var weekData: [(day: String, value: Int)] {
        let calendar = Calendar.current
        let symbols = ["D", "L", "M", "Mi", "J", "V", "S"] // domingo=0 en Calendar
        var result: [(day: String, value: Int)] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let count = attempts.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }.count
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            result.append((day: symbols[weekdayIndex], value: count))
        }
        return result
    }

    var maxValue: Int {
        max(weekData.map { $0.value }.max() ?? 1, 1)
    }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackButton(action: { screen = "home" })
                    Text("Tu progreso")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .background(
                    LinearGradient(colors: [Color(red: 0.498, green: 0.702, blue: 0.612), Color(red: 0.353, green: 0.557, blue: 0.467)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea(edges: .top)
                )

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("\(streakDays)").font(.system(size: 42, weight: .bold)).foregroundColor(.white)
                            Text("días seguidos sin caer").font(.system(size: 13.5)).foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(26)
                        .background(LinearGradient(colors: [.mintDark, .mintDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(18)
                        .shadow(color: .mintDeep.opacity(0.25), radius: 12, y: 6)

                        VStack(spacing: 12) {
                            Text("Esta semana").font(.system(size: 14, weight: .semibold)).foregroundColor(.ink)

                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(weekData, id: \.day) { item in
                                    VStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.mintDark)
                                            .frame(height: CGFloat(item.value) / CGFloat(maxValue) * 100 + 4)
                                        Text(item.day).font(.system(size: 11, weight: .semibold)).foregroundColor(.softGray)
                                    }
                                }
                            }
                            .frame(height: 130, alignment: .bottom)

                            Text("Vas mejorando — menos pausas cada día 🌱")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.mintDeep)
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.75))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mintDark.opacity(0.2), lineWidth: 1))

                        VStack(spacing: 10) {
                            achievementRow("Llevas \(streakDays) día\(streakDays == 1 ? "" : "s") seguido\(streakDays == 1 ? "" : "s")")
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    func achievementRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.mintDark)
            Text(text).font(.system(size: 13.5, weight: .semibold)).foregroundColor(.mintDeep)
            Spacer()
        }
        .padding(13)
        .background(Color.white.opacity(0.75))
        .cornerRadius(12)
    }
}

// MARK: - Pantalla de Ajustes
struct SettingsView: View {
    @Binding var screen: String
    @Binding var userMessage: String
    @Binding var timerDuration: Int
    @Environment(\.modelContext) private var modelContext
    @State private var editedMessage = ""
    @State private var customSites: [String] = []
    @State private var newSite = ""
    @State private var tempDuration = 120
    @State private var justSaved = false
    @State private var durationSaved = false
    @FocusState private var settingsFocused: Bool

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackButton(action: { screen = "home" })
                    Text("Ajustes")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .background(
                    LinearGradient(colors: [Color(red: 0.498, green: 0.702, blue: 0.612), Color(red: 0.353, green: 0.557, blue: 0.467)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea(edges: .top)
                )

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tu razón").font(.system(size: 14, weight: .semibold)).foregroundColor(.ink)

                            TextEditor(text: $editedMessage)
                                .foregroundColor(.ink)
                                .scrollContentBackground(.hidden)
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(11)
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.mintDark.opacity(0.2), lineWidth: 1.5))
                                .focused($settingsFocused)

                            Button(action: {
                                userMessage = editedMessage
                                withAnimation(.easeInOut(duration: 0.2)) { justSaved = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { justSaved = false }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if justSaved { Image(systemName: "checkmark") }
                                    Text(justSaved ? "Guardado" : "Guardar")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(justSaved ? Color.mintDark : Color.mintDeep)
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.75))
                        .cornerRadius(16)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Sitios agregados por ti").font(.system(size: 14, weight: .semibold)).foregroundColor(.ink)

                            if customSites.isEmpty {
                                Text("Aún no has agregado ninguno.")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(.softGray)
                            } else {
                                ForEach(customSites, id: \.self) { site in
                                    HStack {
                                        Text(site).font(.system(size: 13))
                                        Spacer()
                                        Text("🔒 tuyo")
                                            .font(.system(size: 10.5, weight: .semibold))
                                            .foregroundColor(.mintDeep)
                                            .padding(.horizontal, 7).padding(.vertical, 2)
                                            .background(Color(red: 0.933, green: 0.965, blue: 0.945))
                                            .cornerRadius(5)
                                    }
                                }
                            }

                            HStack(spacing: 8) {
                                TextField("ej: sitio-x.com", text: $newSite)
                                    .focused($settingsFocused)
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(9)
                                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.mintDark.opacity(0.2), lineWidth: 1))

                                Button(action: {
                                    guard !newSite.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                    customSites.append(newSite)
                                    newSite = ""
                                }) {
                                    Text("Agregar")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .frame(height: 40)
                                        .background(Color.mintDark)
                                        .cornerRadius(9)
                                }
                            }

                            Text("Nota: por ahora esta lista no se guarda al salir de la pantalla — eso lo resolvemos en el próximo paso con almacenamiento real.")
                                .font(.system(size: 10.5))
                                .foregroundColor(.softGray)
                                .italic()
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.75))
                        .cornerRadius(16)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Duración de la pausa").font(.system(size: 14, weight: .semibold)).foregroundColor(.ink)

                            VStack(spacing: 8) {
                                durationRow(seconds: 120, label: "2 minutos", sublabel: "recomendado")
                                durationRow(seconds: 180, label: "3 minutos", sublabel: "")
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Personalizado: \(tempDuration / 60) min \(tempDuration % 60 > 0 ? "\(tempDuration % 60) seg" : "")")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.ink)

                                Slider(value: Binding(
                                    get: { Double(tempDuration) },
                                    set: { tempDuration = Int($0) }
                                ), in: 120...300, step: 1)
                                .tint(.mintDark)
                                .animation(.easeOut(duration: 0.1), value: tempDuration)
                            }
                            .padding(.top, 4)

                            Button(action: {
                                timerDuration = tempDuration
                                withAnimation(.easeInOut(duration: 0.2)) { durationSaved = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { durationSaved = false }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if durationSaved { Image(systemName: "checkmark") }
                                    Text(durationSaved ? "Guardado" : "Guardar duración")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(durationSaved ? Color.mintDark : Color.mintDeep)
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.75))
                        .cornerRadius(16)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("¿Olvidaste tu clave?").font(.system(size: 14, weight: .semibold)).foregroundColor(.ink)
                            Text("Por seguridad no hay recuperación automática — así nadie más puede \"olvidarla\" a propósito para desactivar tu protección. Si la perdiste, reinstala la app y empieza de nuevo.")
                                .font(.system(size: 12.5))
                                .foregroundColor(.softGray)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.75))
                        .cornerRadius(16)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onTapGesture { dismissKeyboard() }
        .onAppear {
            editedMessage = userMessage
            tempDuration = timerDuration
        }
    }

    func durationRow(seconds: Int, label: String, sublabel: String) -> some View {
        Button(action: { tempDuration = seconds }) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.system(size: 14, weight: .semibold)).foregroundColor(.ink)
                    if !sublabel.isEmpty {
                        Text(sublabel).font(.system(size: 11.5)).foregroundColor(.softGray)
                    }
                }
                Spacer()
                if tempDuration == seconds {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.mintDark)
                } else {
                    Image(systemName: "circle").foregroundColor(Color(red: 0.83, green: 0.88, blue: 0.85))
                }
            }
            .padding(13)
            .background(tempDuration == seconds ? Color(red: 0.933, green: 0.965, blue: 0.945) : Color.white)
            .cornerRadius(11)
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(tempDuration == seconds ? Color.mintDark.opacity(0.4) : Color.mintDark.opacity(0.1), lineWidth: 1.5))
        }
    }
}

// MARK: - Flow layout para los chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                height += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    ContentView()
}
