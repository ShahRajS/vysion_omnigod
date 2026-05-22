// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Vysion';

  @override
  String get readMode => 'Leer';

  @override
  String get describeMode => 'Describir';

  @override
  String get navigateMode => 'Navegar';

  @override
  String get welcomeMessage =>
      'Bienvenido a Vysion, tu copiloto de accesibilidad.';

  @override
  String get onboardingInstruction =>
      'Desliza a la izquierda o derecha para cambiar de modo. Toca para accionar. Desliza hacia abajo para cancelar el habla.';

  @override
  String get startJourney => 'Comenzar';

  @override
  String get cameraPermissionRequired =>
      'Se requiere permiso de cámara para analizar el entorno.';

  @override
  String get locationPermissionRequired =>
      'Se requiere permiso de ubicación para la guía de navegación.';

  @override
  String get microphonePermissionRequired =>
      'Se requiere permiso de micrófono para hablar con el copiloto.';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get settings => 'Ajustes';

  @override
  String get speechRate => 'Velocidad de habla';

  @override
  String get hapticIntensity => 'Intensidad de vibración haptica';

  @override
  String get destinationPlaceholder => '¿A dónde vas?';

  @override
  String get hazardWarning => 'Alerta: ¡Peligro detectado frente a ti!';

  @override
  String get arrived => 'Has llegado a tu destino.';

  @override
  String get ocrReadingError =>
      'No se pudo leer el texto del cartel. Inténtalo de nuevo.';

  @override
  String get navigationCancelled => 'Navegación cancelada.';
}
