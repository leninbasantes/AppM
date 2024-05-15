// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:alerta_global/constants.dart';
import 'package:alerta_global/dashboard_screen.dart';
import 'package:alerta_global/dashboard_sidebarmenu.dart';
import 'package:alerta_global/system_verification.dart';
import 'package:alerta_global/transition_route_observer.dart';
import 'package:alerta_global/utils/json_helper.dart';
import 'package:alerta_global/widgets/fade_in.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';


class DeviceScreen extends StatefulWidget {

  DeviceScreen({super.key});

  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};
  
  static const routeName = '/device';

   

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with SingleTickerProviderStateMixin, TransitionRouteAware {

    BluetoothDevice? _connectedDevice;

  _addDeviceTolist( BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }
      

   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Salir del sistema
  Future<bool> _goToLogin(BuildContext context) {
    return Navigator.of(context)
        .pushReplacementNamed('/auth')
        .then((_) => false);
  }


// Metodo para crear los botones de manera dinámica
  void _sendAlertWhenShake(){
  
    final dataList = jsonDecode(convertToJsonStringQuotes(raw: const DashboardScreen().serviceList)) as List<dynamic>;
  
    dataList.map((entry){
      
      debugPrint(entry["service_default"].toString());
      if(entry["service_default"].toString() == "true"){
          _determinePosition(entry["network_id"].toString(),entry["service_path"].toString(),entry["servicio_id"].toString(), 
                  entry["organization_id"].toString(),entry["organization_name"].toString(),);
      }
      
    }).toList();
    
  }

void _showAlert(String  content ) {
      showDialog(
        context: context,
        builder: ( context) {
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
              child: const Text("Cerrar",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
              ),),
            ),
          ],
          );
        },
      );
      
    }


/// Determinamos la posición actual del dispositivo. Cuando los servicios de localización y los permisos están habilitados
  Future<String> _determinePosition(String? networkId, String? servicePath, String? serviceId,String? organizationId,String? organizationName) async {
    
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
      _showAlert('Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos.');
    } 

    // Accedemos a la posicíon del dispositivo
    final Position position = await Geolocator.getCurrentPosition();

    // Consumimos el servicio de generación de eventos para que vaya a la infraestructura de IOT
    final dio = Dio();
    
        const url = "${Constants.urlPrincipal}/events/";

        final response = await dio.post(url,
          data: {"user_id": UserPreferences.getUserID(), 
                "service_id": serviceId, 
                "network_id": networkId,
                "latitud": position.latitude , 
                "longitud": position.longitude,
                "organization_id": organizationId, 
                "token_fcm": UserPreferences.getFcmToken(),
                "location_name": "Por Definir",
                "location_sector": "Por Definir",
                },
          options: Options(
            validateStatus: (_) => true,
            contentType: Headers.jsonContentType,
            responseType:ResponseType.json,
            headers: {"Authorization":"Bearer ${UserPreferences.getToken()}"},
          ),);

          debugPrint(response.toString());

          final responseService = await dio.post(Constants.urlServicioIot,
          data: {
                
                  "tipoEmergencia":"Nivel1",
                  "coordenadas":{
                      "latitud":position.latitude,
                      "longitud":position.longitude ,
                  },
                  "usuario":UserPreferences.getName(),
                  "organizacion":organizationName,
            },
          options: Options(
            validateStatus: (_) => true,
            contentType: Headers.jsonContentType,
            responseType:ResponseType.json,
          ),);

      final dataList = jsonDecode(responseService.toString()) as Map<String, dynamic>;
      
      if(responseService.toString().contains('error')){
        
        _showAlert(dataList["message"].toString());
      } else {
        
        _showAlert("Alerta Enviada");
      } 
    
        return '';
  }

  final routeObserver = TransitionRouteObserver<PageRoute?>();
  static const headerAniInterval = Interval(.1, .3, curve: Curves.easeOut);
  AnimationController? _loadingController;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.turnOn();
    
    setState(() {
        widget.devicesList.clear();
      });

    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (final ScanResult result in results) {
        if(result.advertisementData.connectable == true && result.advertisementData.advName != ''){
          _addDeviceTolist(result.device);
        }
      }
    });
      
    FlutterBluePlus.startScan( androidUsesFineLocation: true);
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );


  }


   ListView _buildListViewOfDevices() {
    final List<Widget> containers = <Widget>[];
    for (final BluetoothDevice device in widget.devicesList) {
      containers.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: SizedBox(
          
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.advName == '' ? '(unknown device)' : device.advName),
                    Text(device.remoteId.toString()),
                  ],
                ),
              ),
              TextButton(
                style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.red),
                ),
                onPressed: () async {
                  try {
                    device.isConnected ? await device.disconnect(): await device.connect() ;
                  if (device.isConnected) {
                    await device.discoverServices();
                    final List<BluetoothService> services = await device.discoverServices();
                      // ignore: avoid_function_literals_in_foreach_calls
                      services.forEach((service) async {
                        final characteristics = service.characteristics;
                        for(final BluetoothCharacteristic c in characteristics) {
                            await c.setNotifyValue(true,timeout: 200000);
                            c.lastValueStream.listen((value) {                             
                              if(c.properties.notify==true && c.properties.write== false && value.isNotEmpty){
                                  if(value[value.length-1]==1){
                                    _sendAlertWhenShake();
                                  }
                              }
                            });
                        }
                    });
                  } else {
                    await device.discoverServices();
                  } 
                  
                  } on PlatformException catch (e) {
                    if (e.code != 'already_connected') {
                      rethrow;
                    }
                  } finally {
                      await device.discoverServices();
                  }
                  setState(() {
                    _connectedDevice = device;
                  });
                },
                child:  Text(
                  device.isConnected ? 'Desconectar' :'Conectar',
                  style: const TextStyle(color: Colors.white),
                  
                ),
              ),
            ],
          ),
        ),
       ),
      );
    }

    return ListView(
        shrinkWrap: true,
      padding: const EdgeInsets.all(1),
      children: <Widget>[
        ...containers,
      ],
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
      onPressed: () =>  _scaffoldKey.currentState?.openDrawer(),
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
                    const SizedBox(height: 20),
                    const ColoredBox(
                          color: Colors.white,
                          child:  Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:  <Widget>[
                                Text("Dispositivos generadores de alertas",style: TextStyle(fontSize: 20,),),],),
                    ), 
                Container(
                    padding: const EdgeInsets.all(8.0),
                    height: 50,
                    child: Row(
                      children: [
                        const SizedBox(height: 30,width: 90,),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () { widget.devicesList.clear();FlutterBluePlus.startScan(androidUsesFineLocation: true);}, 
                              style:  const ButtonStyle( backgroundColor: WidgetStatePropertyAll(Colors.red), ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children:  [Text('Scanear ',style:  TextStyle(color: Colors.white)),Icon(
                                Icons.search, color: Colors.white, size: 24.0,),],),
                              
                            ),
                          ),
                        ),
                        const SizedBox(height: 30,width: 90,),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.black),
                    Expanded(
                      flex: 8,
                      child: Container(
                          child: _buildListViewOfDevices(),   
                      ),),      
                ],
            ),
            ),             
          ),
        ),
      );
  }


}
