import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

var logWriter = Logger();
String logFileName;
var snowConfig = Snow();
var smaxConfig = Smax();
var mappingConfig = Mapping();

class Mapping {
  var jsonVals;

  void readFromFile() {
    try {
      jsonVals = File('./data/mapping.json').readAsStringSync();
      jsonVals = jsonDecode(jsonVals);
      logWriter.writeLog(logFileName, 'Mapping',
          'Mapping file loaded\n ${jsonVals['Impact']}');
    } catch (e) {
      logWriter.writeLog(logFileName, 'Mapping',
          'ERROR : Error reading Mapping file \n ${e.toString()}');
    }
  }

  void printVals() {
    print(jsonVals['Impact']['1']);
  }
}

class Snow {
  String uname, password, endpointUrl, snowModule, hostName, query;
  void readFromFile() {
    try {
      String comFile = File('./data/snow.json').readAsStringSync();
      var comFileJson = jsonDecode(comFile);
      uname = comFileJson['Uname'];
      password = comFileJson['Pword'];
      //endpointUrl = comFileJson['EndopointURL'];
      snowModule = comFileJson['ModuleName'];
      hostName = comFileJson['HostName'];
      query = comFileJson['Query'];
      endpointUrl = 'https://$hostName/api/now/table/$snowModule?$query';
      logWriter.writeLog(logFileName, 'SNOW Config Init',
          'SNOW ${comFile} Configuration Loaded successfully');
      print('SNOW snow.json Configuration Loaded successfully');
    } catch (e) {
      print('SNOW Config Init, ERROR: ${e.toString()}');
      logWriter.writeLog(
          logFileName, 'SNOW Config Init', 'ERROR: ${e.toString()}');
    }
  }
}

class Smax {
  String uname,
      password,
      hostName,
      tenantId,
      endpointUrl,
      authUrl,
      smaxEntity,
      certFilePath;
  String authCookie;
  void readFromFile() {
    try {
      String comFile = File('./data/smax.json').readAsStringSync();
      var comFileJson = jsonDecode(comFile);
      uname = comFileJson['Uname'];
      password = comFileJson['Pword'];
      //endpointUrl = comFileJson['EndopointURL'];
      hostName = comFileJson['HostName'];
      tenantId = comFileJson['TenantId'];
      endpointUrl = 'https://$hostName/rest/$tenantId/ems/bulk';
      authUrl =
          'https://$hostName/auth/authentication-endpoint/authenticate/login?TENANTID=$tenantId';
      //authUrl = 'https://$hostName/rest/$tenantId/ems/bulk';
      smaxEntity = comFileJson['SmaxEntity'];
      certFilePath = comFileJson['CertFilePath'];
      logWriter.writeLog(logFileName, 'SMAX Config Init',
          'SMAX ${comFile} Configuration Loaded successfully');
      print('SMAX smax.json Configuration Loaded successfully');
    } catch (e) {
      print('SMAX Config Init , ERROR: ${e.toString()}');
      logWriter.writeLog(
          logFileName, 'SMAX Config Init', 'ERROR: ${e.toString()}');
    }
  }
}

class Logger {
  String filename;
  String mappingName;

  void intiFile(fname) {
    filename = fname;
  }

  void writeLogInit(logFileName, mapping, msg) {
    var loggerFilename = File(logFileName);
    var now = DateTime.now();

    loggerFilename.writeAsStringSync('${now},\t$mapping,\t$msg\n');
  }

  void writeLog(logFileName, mapping, msg) {
    var now = DateTime.now();
    var loggerFilename = File(logFileName);
    loggerFilename.writeAsStringSync('${now},\t$mapping,\t$msg\n',
        mode: FileMode.append);
  }
}

class CommonConfig {
  String logFileName;
  bool logRotationEnabled;

  void intiValues() {
    try {
      String comFile = File('./data/common.json').readAsStringSync();
      logWriter.writeLogInit(
          './log/Init.Log', 'Init', 'common.json file loaded');
      logWriter.writeLog('./log/Init.Log', 'Init', comFile);
      var comFileJson = jsonDecode(comFile);
      print(comFileJson);
      print(comFileJson['LogFileName']);
      logFileName = comFileJson['LogFileName'];
      logWriter.writeLog('./log/Init.Log', 'Init',
          'logFileName=${comFileJson['LogFileName']}');
      logWriter.writeLog('./log/Init.Log', 'Init',
          'Rest of the logs will appear in this file ${comFileJson['LogFileName']}');
    } catch (e) {
      logWriter.writeLogInit('./log/Init.Log', 'Init', e.toString());
      print(e.toString());
    }
  }
}

void main(List<String> arguments) {
  //1. Initiating Common config files

  var commonConfig = CommonConfig();
  commonConfig.intiValues();
  logFileName = commonConfig.logFileName;
  print("Loaded initial configuration");
  //2. Initiating logger

  logWriter.intiFile(commonConfig.logFileName);
  logWriter.writeLogInit(commonConfig.logFileName, 'Logger', 'Logger Initated');
  print("Logger Initated");
  //3. Reading SNOW configuration

  snowConfig.readFromFile();

  //4. Reading SMAX Configuration

  smaxConfig.readFromFile();

  //5. Loading the mapping file
  mappingConfig.readFromFile();

  //6. Reading SMAX Auth

  setSMAXAuth();

  //7. Execute SNOW to SMAX
  snowToSMAXExecute();
}

void snowToSMAXExecute() async {
  var auth = 'Basic ' +
      base64Encode(utf8.encode('${snowConfig.uname}:${snowConfig.password}'));

  try {
    http.Response r = await http.get('${snowConfig.endpointUrl}',
        headers: <String, String>{'authorization': auth});
    if (r.statusCode != 200) {
      logWriter.writeLog(
          logFileName, 'SNOW', 'Error:${r.statusCode} ${r.body}');
    } else {
      logWriter.writeLog(
          logFileName, 'SNOW', 'SNOW Fetch Success:${r.statusCode} ${r.body}');
      var snowResponse = jsonDecode(r.body);
      //print(snowResponse['result'].length );
      logWriter.writeLog(logFileName, 'SNOW',
          "Fetched :${snowResponse['result'].length} tickets");
      print(
          "Fetched :${snowResponse['result'].length} tickets (${snowConfig.endpointUrl})");
      for (var item in snowResponse['result']) {
        //print('${item['number']} ${item['state']} ${item['impact']}');
        print('Processing ticket ${item['number']}');
        logWriter.writeLog(logFileName, "SMAX Bulk Create",
            'Processing ticket ${item['number']}');
        var imPayload = {
          'entities': [
            {
              'entity_type': '${smaxConfig.smaxEntity}',
              'properties': {
                'RegisteredForActualService': '11359',
                //TO-DO Fetch service
                'DisplayLabel':
                    '>Created from SNOW <b> ID: ${item['number']} ${item['short_description']}',
                'Description':
                    '<p>${item['description']}</p><br>Created from SNOW <b> ID: ${item['number']} </b>',
                'Urgency': '${getSMAXUrgency(item['urgency'])}',
                'ImpactScope': '${getSMAXImpact(item['impact'])}',
                'DetectedEntities': '{\'complexTypeProperties\':[]}',
                'UserOptions':
                    '{\'complexTypeProperties\':[{\'properties\':{}}]}'
              }
            }
          ],
          'operation': 'CREATE'
        };
        logWriter.writeLog(
            logFileName, "SMAX Bulk Create", 'JSON\n $imPayload');
        sendToSMAX(json.encode(imPayload));
      }
    }
    //print(r.statusCode);
    //print(r.body);

  } catch (e) {
    logWriter.writeLog(logFileName, 'SNOW', 'Error:${e.toString()}');
  }
}

void setSMAXAuth() async {
  SecurityContext context = new SecurityContext();
  context.setTrustedCertificates(smaxConfig.certFilePath);
  var smaxHttpClient = new HttpClient(context: context);

  try {
    HttpClientRequest request =
        await smaxHttpClient.postUrl(Uri.parse(smaxConfig.authUrl));
    var payload = {
      'Login': '${smaxConfig.uname}',
      'Password': '${smaxConfig.password}',
    };
    request.write(json.encode(payload));
    HttpClientResponse response = await request.close();
    if (response.statusCode == 200) {
      var authToken = await response.transform(utf8.decoder).join();
      smaxConfig.authCookie = authToken;
      print('SMAX Auth Successfull');
      logWriter.writeLog(
          logFileName, 'SMAX', 'SMAX Auth Successfull: Token \n ${authToken} ');
    } else {
      var erMsg = await response.transform(utf8.decoder).join();
      print(
          'ERROR SMAX Auth Error: Status Code ${response.statusCode} Message \n ${erMsg} ');
      logWriter.writeLog(logFileName, 'SMAX',
          'ERROR SMAX Auth Error: Status Code ${response.statusCode} Message \n ${erMsg} ');
    }
  } catch (e) {
    logWriter.writeLog(logFileName, 'SMAX',
        'ERROR SMAX Create Bulk Error: Exception Occured \n ${e.toString()} ');
    print(
        'ERROR SMAX Create Bulk Error: Exception Occured \n ${e.toString()} ');
  }
}

void sendToSMAX(payload) async {
  SecurityContext context = new SecurityContext();
  context.setTrustedCertificates(smaxConfig.certFilePath);
  var smaxHttpClient = new HttpClient(context: context);
  try {
    HttpClientRequest request =
        await smaxHttpClient.postUrl(Uri.parse(smaxConfig.endpointUrl));
    request.headers.set('Cookie', 'LWSSO_COOKIE_KEY=${smaxConfig.authCookie}');
    request.write(payload);
    HttpClientResponse response = await request.close();
    if (response.statusCode == 200) {
      var responseJson = await response.transform(utf8.decoder).join();
      smaxConfig.authUrl = responseJson;
      print('SMAX Create Bulk Successfull');
      logWriter.writeLog(logFileName, 'SMAX',
          'SMAX Create Bulk Successfull: Response JSON \n ${responseJson} ');
    } else {
      var erMsg = await response.transform(utf8.decoder).join();
      print(
          'ERROR SMAX Create Bulk Error: Status Code ${response.statusCode} Message \n ${erMsg} ');
      logWriter.writeLog(logFileName, 'SMAX',
          'ERROR SMAX Create Bulk Error: Status Code ${response.statusCode} Message \n ${erMsg} ');
    }
  } catch (e) {
    logWriter.writeLog(logFileName, 'SMAX',
        'ERROR SMAX Create Bulk Error: Exception Occured \n ${e.toString()} ');
    print(
        'ERROR SMAX Create Bulk Error: Exception Occured \n ${e.toString()} ');
  }
}

String getSMAXImpact(sImpact) {
  return mappingConfig.jsonVals['Impact'][sImpact];
}

String getSMAXUrgency(sUrgency) {
  return mappingConfig.jsonVals['Urgency'][sUrgency];
}

//TODO
String getSMAXService(sService) {}

//TODO
String getSNOWServiceName(sServiceCode) {}
