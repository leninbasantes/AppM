// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:alerta_global/constants.dart';
import 'package:alerta_global/dashboard_sidebarmenu.dart';
import 'package:alerta_global/service/api_service.dart';
import 'package:alerta_global/system_verification.dart';
import 'package:alerta_global/transition_route_observer.dart';
import 'package:alerta_global/widgets/fade_in.dart';
import 'package:alerta_global/widgets/round_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  static String _serviceList = "";

  String get serviceList => _serviceList;

  set serviceList(String value) {
    if (value.isNotEmpty) {
      _serviceList = value;
    }
  }

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, TransitionRouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Salir del sistema
  Future<bool> _goToLogin(BuildContext context) async {
    await UserPreferences.setLoggedIn(false);
    if (!mounted) return false; // Verifica si el widget sigue montado
    Navigator.of(context).pushReplacementNamed('/auth');
    return false;
  }

// Metodo para crear los botones de manera dinámica
  Future<void> _sendAlertWhenShake() async {
    // Obtén la cadena JSON de los servicios de manera asíncrona
    final String? serviceListJson = await getServiceList();

    // Si el JSON es nulo, simplemente retorna sin hacer nada
    if (serviceListJson == null) return;

    // Decodifica el JSON a una lista dinámica
    final List<dynamic> dataList = jsonDecode(serviceListJson) as List<dynamic>;

    // Itera sobre cada elemento en la lista
    for (final entry in dataList) {
      debugPrint(entry["service_default"].toString());

      // Verifica si el valor de "service_default" es "true"
      if (entry["service_default"].toString() == "true") {
        // Llama a _determinePosition con los valores adecuados
        _determinePosition(
          entry["origin_id"].toString(),
          entry["service_path"].toString(),
          entry["servicio_id"].toString(),
          entry["owner_id"].toString(),
          entry["owner_name"].toString(),
          entry["sub_origin_id"]
              .toString(), // Asegúrate de que esta llave exista o maneja posibles null
          entry["type"].toString(),
        );
      }
    }
  }

  Future<String?> getServiceList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('serviceList');
  }

  // Metodo para crear los botones de manera dinámica
  Future<List<Widget>> _getGridButtonList() async {
    final String? serviceListJson = await getServiceList();
    if (serviceListJson == null) return <Widget>[];

    // Usa el cast explícito para asegurar que jsonDecode devuelve una List<dynamic>.
    final List<dynamic> dataList =
        jsonDecode(serviceListJson) as List<dynamic>;
    final List<Widget> widgetList = <Widget>[];

    for (final entry in dataList) {
      if (entry["service_default"].toString() != "true") {
        widgetList.add(
          _buildButton(
            interval: const Interval(0, 0.75),
            icon: Image.asset('assets/images/${entry["service_icon"]}'),
            label: entry["service_name"].toString(),
            originId: entry["origin_id"].toString(),
            servicePath: entry["service_path"].toString(),
            serviceId: entry["servicio_id"].toString(),
            ownerId: entry["owner_id"].toString(),
            ownerName: entry["owner_name"].toString(),
            subOriginId: entry["sub_origin_id"].toString(),
            type: entry["type"].toString(),
          ),
        );
      }
    }

    return widgetList;
  }

  /// Determinamos la posición actual del dispositivo. Cuando los servicios de localización y los permisos están habilitados
  Future<String> _determinePosition(
      String? originId,
      String? servicePath,
      String? serviceId,
      String? ownerId,
      String? ownerName,
      String? subOriginId,
      String? type,) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Probamos si el servicio de localización está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si el servicio de localizacion no esta habilitado no continua accediendo a la posición del usuario
      _showAlert('El servicio de ubicación está deshabilitado');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Se deniegan los permisos, la próxima vez puede intentar solicitar permisos nuevamente
        _showAlert('Se deniegan los permisos de ubicación');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Los permisos se denegaron para siempre, maneje adecuadamente.
      _showAlert(
          'Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos.',);
    }

    // Accedemos a la posicíon del dispositivo
    final Position position = await Geolocator.getCurrentPosition();

    var url = "";
    Map<String, dynamic> body = {};

    if (type == 'I') {
      url = "${Constants.urlPrincipal}/event-individuals/";
      body = {
        "user_id": UserPreferences.getUserID(),
        "latitud": position.latitude,
        "longitud": position.longitude,
        "service_id": serviceId,
        "subNetwork_id": originId,
        "location_name": "Por Definir",
        "location_sector": "Por Definir",
        "individual_id": ownerId,
      };
    }

    if (type == 'O') {
      url = "${Constants.urlPrincipal}/event-organizations/";
      body = {
        "user_id": UserPreferences.getUserID(),
        "latitud": position.latitude,
        "longitud": position.longitude,
        "service_id": serviceId,
        "branch_id": originId,
        "organization_id": ownerId,
        "location_name": "Por Definir",
        "location_sector": "Por Definir",
        "subNetwork_id": subOriginId,
      };
    }

    debugPrint("Esta es la URL");
    debugPrint(url);
    debugPrint("Esto el cuerpo");
    final String testing = json.encode(body);
    debugPrint(testing);

    try {
      final responseService = await makeRequest(
          url: url,
          data: body,
          headers: {"Authorization": "Bearer ${UserPreferences.getToken()}"},);

      final String jsonString = json.encode(responseService);
      debugPrint(jsonString);
      // _showAlert("Se envio a eventos");
    } catch (e) {
      debugPrint(e.toString());
      // _showAlert("No se puedo enviqar a eventos");
    }

    // final response = await makeRequest(url: url, data: body, headers: {
    //   "Authorization": "Bearer ${UserPreferences.getToken()}"
    // });

    // debugPrint(response.toString());

    try {
      final responseService =
          await makeRequest(url: Constants.urlServicioIot, data: {
        "tipoEmergencia": "Nivel1",
        "coordenadas": {
          "latitud": position.latitude,
          "longitud": position.longitude,
        },
        "usuario": UserPreferences.getName(),
        "organizacion": ownerName,
      }, headers: {
        "Authorization": "Bearer ${UserPreferences.getToken()}",
      },);

      final String jsonString = json.encode(responseService);
      debugPrint(jsonString);
      _showAlert("Evento Generado");
    } catch (e) {
      _showAlert("Evento Generado");
    }

    return '';
  }

  final routeObserver = TransitionRouteObserver<PageRoute?>();
  static const headerAniInterval = Interval(.1, .3, curve: Curves.easeOut);
  AnimationController? _loadingController;

  @override
  void initState() {
    super.initState();

    /////////// Inicio - Metodo para detectar el movimiento al agitar el celular //////////////

    // final ShakeDetector detector = ShakeDetector.autoStart(
    //   onShake: () {
    //     _sendAlertWhenShake();
    //     // Do stuff on phone shake
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text('ALERTA ENVIADA!'),
    //       ),
    //     );
    //   },
    // );

    // detector.startListening();
    /////////// Fin - Metodo para detectar el movimiento al agitar el celular //////////////

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
      this,
      ModalRoute.of(context) as PageRoute<dynamic>?,
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _loadingController!.dispose();
    super.dispose();
  }

  @override
  void didPushAfterTransition() => _loadingController!.forward();

  AppBar _buildAppBar(ThemeData theme) {
    final menuBtn = IconButton(
      color: theme.colorScheme.secondary,
      icon: const Icon(FontAwesomeIcons.bars),
      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
    );
    final signOutBtn = IconButton(
      icon: const Icon(FontAwesomeIcons.rightFromBracket),
      color: theme.colorScheme.secondary,
      onPressed: () => _goToLogin(context),
    );
    final title = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Image.asset(
              'assets/images/alertaglobal.png',
              filterQuality: FilterQuality.high,
              height: 40,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );

    return AppBar(
      leading: FadeIn(
        controller: _loadingController,
        offset: .3,
        curve: headerAniInterval,
        child: menuBtn,
      ),
      actions: <Widget>[
        FadeIn(
          controller: _loadingController,
          offset: .3,
          curve: headerAniInterval,
          fadeDirection: FadeDirection.endToStart,
          child: signOutBtn,
        ),
      ],
      title: title,
      backgroundColor: theme.primaryColor.withOpacity(.1),
      elevation: 0,
    );
  }

  Widget _buildButton({
    Widget? icon,
    String? label,
    required Interval interval,
    String? subOriginId,
    String? originId,
    String? servicePath,
    String? serviceId,
    String? ownerId,
    String? ownerName,
    String? type,
  }) {
    return RoundButton(
      icon: icon,
      label: label,
      loadingController: _loadingController,
      interval: Interval(
        interval.begin,
        interval.end,
        curve: const ElasticOutCurve(0),
      ),
      onPressed: () {
        _determinePosition(originId, servicePath, serviceId, ownerId, ownerName,
            subOriginId, type,);
      },
    );
  }

  Widget _buildDashboardGrid() {
    return FutureBuilder<List<Widget>>(
      future: _getGridButtonList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 15),
            crossAxisCount: 3,
            crossAxisSpacing: 10, // Espaciado horizontal entre los ítems
            mainAxisSpacing: 10, // Espaciado vertical entre los ítems
            childAspectRatio:
                0.6, // Proporción entre la anchura y la altura de los ítems
            children: snapshot.data!,
          );
        } else {
          return const Center(child: Text("No data available"));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldKey,
          appBar: _buildAppBar(theme),
          drawer: const NavBar(),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFFFFFFF),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 30),
                SizedBox(
                  height: 200,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      _sendAlertWhenShake();
                    },
                    clipBehavior: Clip.antiAlias,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Image.asset('assets/images/boton-principal.png',
                        fit: BoxFit.cover,),
                  ),
                ),
                const SizedBox(height: 30),
                ColoredBox(
                  color: Colors.grey.shade200,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Servicios Adicionales",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Container(
                    child: _buildDashboardGrid(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlert(String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: const Text(
              "Mensaje del Sistema",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: Text(content),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          alignment: Alignment.center,
          actions: <Widget>[
            MaterialButton(
              color: Colors.red,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cerrar",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
