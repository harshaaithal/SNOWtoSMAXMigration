import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'snow_group.dart';
import 'snow_user.dart';
import 'smax_user.dart';
import 'mongoDB.dart';

import 'package:logger/logger.dart';

final logger = Logger(
    printer: PrettyPrinter(
  methodCount: 0,
  errorMethodCount: 5,
  lineLength: 150,
  colors: true,
  printEmojis: true,
  printTime: false,
));
var loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

SnowUser snow_user;
SmaxPerson smax_user;
MongoDB mongoDB;
SnowGroup snow_group;
var logWriter = CustomLogger();
String logFileName;
var snowConfig = Snow();
var smaxConfig = Smax();
var mappingConfig = Mapping();
var processedRecords = ProcessedRecords();
var processedRecordsFileName =
    'SNOWtoSMAXProcessedRecord-${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}-${DateTime.now().hour}-${DateTime.now().minute}-${DateTime.now().second}.csv';

class ProcessedRecords {
  var snowId;
  var smaxId;
  var status;
  var elapseTime;
}

class Mapping {
  var jsonVals;

  void readFromFile() {
    try {
      jsonVals = File('./data/mapping.json').readAsStringSync();
      jsonVals = jsonDecode(jsonVals);
      logWriter.writeLog(logFileName, 'Mapping',
          'Mapping file loaded\n ${jsonVals['Impact']}');
      logger.i('Mapping file loaded\n ${jsonVals['Impact']}');
    } catch (e) {
      logWriter.writeLog(logFileName, 'Mapping',
          'ERROR : Error reading Mapping file \n ${e.toString()}');
    }
  }

  void printVals() {
    logger.i(jsonVals['Impact']['1']);
  }
}

class Snow {
  String uname, password, endpointUrl, snowModule, hostName, query;
  void readFromFile() {
    try {
      var comFile = File('./data/snow PM.json').readAsStringSync();
      //TODO: Make it generic
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
      logger.i('SNOW snow.json Configuration Loaded successfully');
    } catch (e) {
      logger.e('SNOW Config Init, ERROR: ${e.toString()}');
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
      defaultServiceCode,
      certFilePath;
  String authCookie;
  void readFromFile() {
    try {
      var comFile = File('./data/smax PM.json').readAsStringSync();
      var comFileJson = jsonDecode(comFile);
      uname = comFileJson['Uname'];
      password = comFileJson['Pword'];
      //endpointUrl = comFileJson['EndopointURL'];
      hostName = comFileJson['HostName'];
      tenantId = comFileJson['TenantId'];
      smaxEntity = comFileJson['SmaxEntity'];
      defaultServiceCode = comFileJson['DefaultServiceCode'];
      endpointUrl = smaxEntity != 'Person'
          ? 'https://$hostName/rest/$tenantId/ems/bulk'
          : 'https://$hostName/rest/$tenantId/ums/managePersons';
      if (uname == 'suite-admin') {
        authUrl =
            'https://$hostName/auth/authentication-endpoint/authenticate/login/';
      } else {
        authUrl =
            'https://$hostName/auth/authentication-endpoint/authenticate/login?TENANTID=$tenantId';
      }
      //authUrl = 'https://$hostName/rest/$tenantId/ems/bulk';

      certFilePath = comFileJson['CertFilePath'];
      logWriter.writeLog(logFileName, 'SMAX Config Init',
          'SMAX ${comFile} Configuration Loaded successfully');
      logger.i('SMAX smax.json Configuration Loaded successfully');
    } catch (e) {
      logger.e('SMAX Config Init , ERROR: ${e.toString()}');
      logWriter.writeLog(
          logFileName, 'SMAX Config Init', 'ERROR: ${e.toString()}');
    }
  }
}

class CustomLogger {
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

  void writeStatusInit() {
    var statusFileName = File('./data/${processedRecordsFileName}');
    statusFileName
        .writeAsString('SnowID,SMAXId,Status,Time(in millisec),UseCase\n');
  }

  void writeStatus() {
    var statusFileName = File('./data/${processedRecordsFileName}');
    statusFileName.writeAsString(
        '${processedRecords.snowId},${processedRecords.smaxId},${processedRecords.status},${processedRecords.elapseTime}\n',
        mode: FileMode.append);
  }
}

class CommonConfig {
  String logFileName;
  bool logRotationEnabled;

  void intiValues() {
    try {
      var comFile = File('./data/common.json').readAsStringSync();
      logWriter.writeLogInit(
          './log/Init.Log', 'Init', 'common.json file loaded');
      logWriter.writeLog('./log/Init.Log', 'Init', comFile);
      var comFileJson = jsonDecode(comFile);
      logger.i(comFileJson);
      logger.i(comFileJson['LogFileName']);
      logFileName = comFileJson['LogFileName'];
      logWriter.writeLog('./log/Init.Log', 'Init',
          'logFileName=${comFileJson['LogFileName']}');
      logWriter.writeLog('./log/Init.Log', 'Init',
          'Rest of the logs will appear in this file ${comFileJson['LogFileName']}');
    } catch (e) {
      logWriter.writeLogInit('./log/Init.Log', 'Init', e.toString());
      logger.i(e.toString());
    }
  }
}

Future<void> main(List<String> arguments) async {
  //1. Initiating Common config files

  var commonConfig = CommonConfig();
  commonConfig.intiValues();
  logFileName = commonConfig.logFileName;
  logger.i('Loaded initial configuration');
  //2. Initiating logger

  logWriter.intiFile(commonConfig.logFileName);
  logWriter.writeLogInit(commonConfig.logFileName, 'Logger', 'Logger Initated');
  logger.i('Logger Initated');
  //3. Reading SNOW configuration

  snowConfig.readFromFile();

  //4. Reading SMAX Configuration

  smaxConfig.readFromFile();

  //5. Loading the mapping file
  mappingConfig.readFromFile();

  //6. Reading SMAX Auth

  setSMAXAuth();

  //7. Writinng mongoDB status
  mongoDB = MongoDB();
  logWriter.writeLog(logFileName, 'DB Status', await mongoDB.initDB());

  //7. Execute SNOW to SMAX
  initiateSNOWtoSMAX('${smaxConfig.smaxEntity}-${snowConfig.snowModule}');
}

void initiateSNOWtoSMAX(exeUseCase) async {
  switch (exeUseCase) {
    case 'Incident-incident':
      await snowToSMAXExecute_IM();
      break;
    case 'Person-sys_user':
      await snowToSMAXExecute_Person();
      break;
    case 'PersonGroup-sys_user_group':
      await snowToSMAXExecute_PersonGroup();
      break;
    case 'Problem-problem':
      await snowToSMAXExecute_PM();
      break;
    default:
  }
}

void snowToSMAXExecute_PersonGroup() async {
  processedRecordsFileName =
      'SNOWtoSMAXProcessedRecord-PersonGroup-sys_user_group-${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}-${DateTime.now().hour}-${DateTime.now().minute}-${DateTime.now().second}.csv';
  logWriter.writeStatusInit();
  var smaxPersonGroupJson = {};
  //SNOW Login
  var auth = 'Basic ' +
      base64Encode(utf8.encode('${snowConfig.uname}:${snowConfig.password}'));
  try {
    var r = await http.get('${snowConfig.endpointUrl}',
        headers: <String, String>{'authorization': auth});
    if (r.statusCode != 200) {
      logWriter.writeLog(
          logFileName, 'SNOW', 'Error:${r.statusCode} ${r.body}');
    } else {
      logWriter.writeLog(
          logFileName, 'SNOW', 'SNOW Fetch Success:${r.statusCode} ${r.body}');
      snow_group = SnowGroup.fromJson(jsonDecode('${r.body}'));
      //logger.i(snowResponse['result'].length );
      logWriter.writeLog(
          logFileName, 'SNOW', 'Fetched :${snow_group.result.length} tickets');
      logger.i(
          'Fetched :${snow_group.result.length} tickets (${snowConfig.endpointUrl})');
      for (var item in snow_group.result) {
        processedRecords.snowId = '${item.name}';

        logger.i('Processing ticket ${item.name}');
        logWriter.writeLog(
            logFileName, 'SMAX Bulk Create', 'Processing ticket ${item.name}');
        smaxPersonGroupJson = {
          'entities': [
            {
              'entity_type': 'PersonGroup',
              'properties': {
                'GroupType': 'Organizational',
                'Name': '${item.name}',
                'Upn': '${item.name}'
              }
            }
          ],
          'operation': 'CREATE'
        };
        logWriter.writeLog(logFileName, 'SMAX Bulk Create',
            'JSON::${json.encode(smaxPersonGroupJson)}\n');
        await sendToSMAX(json.encode(smaxPersonGroupJson), 'mpa');
      }
    }
    //logger.i(r.statusCode);
    //logger.i(r.body);

  } catch (e) {
    logWriter.writeLog(logFileName, 'SNOW', 'Error:${e.toString()}');
  }
}

void snowToSMAXExecute_Person() async {
  processedRecordsFileName =
      'SNOWtoSMAXProcessedRecord-Person-sys_user-${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}-${DateTime.now().hour}-${DateTime.now().minute}-${DateTime.now().second}.csv';
  logWriter.writeStatusInit();
  var smaxPersonJson = {};
  //SNOW Login
  var auth = 'Basic ' +
      base64Encode(utf8.encode('${snowConfig.uname}:${snowConfig.password}'));
  try {
    var r = await http.get('${snowConfig.endpointUrl}',
        headers: <String, String>{'authorization': auth});
    if (r.statusCode != 200) {
      logWriter.writeLog(
          logFileName, 'SNOW', 'Error:${r.statusCode} ${r.body}');
    } else {
      logWriter.writeLog(
          logFileName, 'SNOW', 'SNOW Fetch Success:${r.statusCode} ${r.body}');
      snow_user = SnowUser.fromJson(jsonDecode('${r.body}'));
      //logger.i(snowResponse['result'].length );
      logWriter.writeLog(
          logFileName, 'SNOW', 'Fetched :${snow_user.result.length} tickets');
      logger.i(
          'Fetched :${snow_user.result.length} tickets (${snowConfig.endpointUrl})');
      for (var item in snow_user.result) {
        processedRecords.snowId = '${item.userName}';

        logger.i('Processing ticket ${item.userName}');
        logWriter.writeLog(logFileName, 'SMAX Bulk Create',
            'Processing ticket ${item.userName}');

        if (item.manager == null && item.roles == '') {
          smaxPersonJson = {
            'operation': 'CREATE_OR_UPDATE',
            'users': [
              {
                'properties': {
                  'FirstName': '${item.firstName}',
                  'LastName': '${item.lastName}',
                  'Email': '${item.email}',
                  'Upn': '${item.userName}',
                  'IsMaasUser': 'FALSE'
                }
              }
            ]
          };
        } else if (item.manager != null && item.roles == '') {
          var managerEmail = await getManagerEmail(item.manager.link);
          smaxPersonJson = {
            'operation': 'CREATE_OR_UPDATE',
            'users': [
              {
                'properties': {
                  'FirstName': '${item.firstName}',
                  'LastName': '${item.lastName}',
                  'Email': '${item.email}',
                  'Upn': '${item.userName}',
                  'IsMaasUser': 'FALSE',
                  'Manager': '$managerEmail'
                }
              }
            ]
          };
        } else if (item.manager != null && item.roles != '') {
          var managerEmail = await getManagerEmail(item.manager.link);
          smaxPersonJson = {
            'operation': 'CREATE_OR_UPDATE',
            'users': [
              {
                'properties': {
                  'FirstName': '${item.firstName}',
                  'LastName': '${item.lastName}',
                  'Email': '${item.email}',
                  'Upn': '${item.userName}',
                  'AuthenticationType': 'DB',
                  'Manager': '$managerEmail'
                },
                'roles': {
                  'REPLACE': [item.roles]
                },
              }
            ]
          };
        } else if (item.manager == null && item.roles != '') {
          smaxPersonJson = {
            'operation': 'CREATE_OR_UPDATE',
            'users': [
              {
                'properties': {
                  'FirstName': '${item.firstName}',
                  'LastName': '${item.lastName}',
                  'Email': '${item.email}',
                  'Upn': '${item.userName}',
                  'AuthenticationType': 'DB'
                },
                'roles': {
                  'REPLACE': [item.roles]
                },
              }
            ]
          };
        }
        logWriter.writeLog(logFileName, 'SMAX Bulk Create',
            'JSON::${json.encode(smaxPersonJson)}\n');
        await sendToSMAX(json.encode(smaxPersonJson), 'mpa');
      }
    }
    //logger.i(r.statusCode);
    //logger.i(r.body);

  } catch (e) {
    logWriter.writeLog(logFileName, 'SNOW', 'Error:${e.toString()}');
  }
}

Future<dynamic> getManagerEmail(String managerLink) async {
  try {
    var auth = 'Basic ' +
        base64Encode(utf8.encode('${snowConfig.uname}:${snowConfig.password}'));
    var r = await http
        .get(managerLink, headers: <String, String>{'authorization': auth});
    if (r.statusCode == 200) {
      var snowResponse = jsonDecode(r.body);
      logger.i(snowResponse['result']['email']);
      return snowResponse['result']['email'];
    } else {
      return null;
    }
  } catch (e) {
    logger.i(e.message);
    return null;
  }
}

void snowToSMAXExecute_IM() async {
  logWriter.writeStatusInit();
  var serviceCode;
  var auth = 'Basic ' +
      base64Encode(utf8.encode('${snowConfig.uname}:${snowConfig.password}'));

  try {
    var r = await http.get('${snowConfig.endpointUrl}',
        headers: <String, String>{'authorization': auth});
    if (r.statusCode != 200) {
      logWriter.writeLog(
          logFileName, 'SNOW', 'Error:${r.statusCode} ${r.body}');
    } else {
      logWriter.writeLog(
          logFileName, 'SNOW', 'SNOW Fetch Success:${r.statusCode} ${r.body}');
      var snowResponse = jsonDecode(r.body);
      //logger.i(snowResponse['result'].length );
      logWriter.writeLog(logFileName, 'SNOW',
          "Fetched :${snowResponse['result'].length} tickets");
      logger.i(
          "Fetched :${snowResponse['result'].length} tickets (${snowConfig.endpointUrl})");
      for (var item in snowResponse['result']) {
        processedRecords.snowId = '${item['number']}';
        //logger.i('${item['number']} ${item['state']} ${item['impact']}');
        try {
          logger.i('${item['cmdb_ci']['value']}');
          serviceCode = await getSMAXService(
              item['cmdb_ci']['value'], smaxConfig.authCookie);
        } catch (e) {
          serviceCode = smaxConfig.defaultServiceCode;
        }
        logger.i('service code ${serviceCode}');
        logger.i('Processing ticket ${item['number']}');
        logWriter.writeLog(logFileName, 'SMAX Bulk Create',
            'Processing ticket ${item['number']}');
        var imPayload = {
          'entities': [
            {
              'entity_type': '${smaxConfig.smaxEntity}',
              'properties': {
                'RegisteredForActualService': '${serviceCode}',
                'DisplayLabel':
                    'Demo Run -2 <b> ID: ${item['number']} ${item['short_description']}',
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
            logFileName, 'SMAX Bulk Create', 'JSON\n $imPayload');
        await sendToSMAX(json.encode(imPayload), 'ems');
      }
    }
    //logger.i(r.statusCode);
    //logger.i(r.body);

  } catch (e) {
    logWriter.writeLog(logFileName, 'SNOW', 'Error:${e.toString()}');
  }
}

void snowToSMAXExecute_PM() async {
  logWriter.writeStatusInit();
  var serviceCode;
  var auth = 'Basic ' +
      base64Encode(utf8.encode('${snowConfig.uname}:${snowConfig.password}'));

  try {
    var r = await http.get('${snowConfig.endpointUrl}',
        headers: <String, String>{'authorization': auth});
    if (r.statusCode != 200) {
      logWriter.writeLog(
          logFileName, 'SNOW', 'Error:${r.statusCode} ${r.body}');
    } else {
      logWriter.writeLog(
          logFileName, 'SNOW', 'SNOW Fetch Success:${r.statusCode} ${r.body}');
      var snowResponse = jsonDecode(r.body);
      //logger.i(snowResponse['result'].length );
      logWriter.writeLog(logFileName, 'SNOW',
          "Fetched :${snowResponse['result'].length} tickets");
      logger.i(
          "Fetched :${snowResponse['result'].length} tickets (${snowConfig.endpointUrl})");
      for (var item in snowResponse['result']) {
        processedRecords.snowId = '${item['number']}';
        //logger.i('${item['number']} ${item['state']} ${item['impact']}');
        try {
          logger.i('${item['cmdb_ci']['value']}');
          serviceCode = await getSMAXService(
              item['cmdb_ci']['value'], smaxConfig.authCookie);
        } catch (e) {
          serviceCode = smaxConfig.defaultServiceCode;
        }
        logger.i('service code ${serviceCode}');
        logger.i('Processing ticket ${item['number']}');
        logWriter.writeLog(logFileName, 'SMAX Bulk Create',
            'Processing ticket ${item['number']}');
        var imPayload = {
          'entities': [
            {
              'entity_type': '${smaxConfig.smaxEntity}',
              'properties': {
                'RegisteredForActualService': '${serviceCode}',
                'DisplayLabel':
                    'Demo Run -2 <b> ID: ${item['number']} ${item['short_description']}',
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
            logFileName, 'SMAX Bulk Create', 'JSON\n $imPayload');
        await sendToSMAX(json.encode(imPayload), 'ems');
      }
    }
    //logger.i(r.statusCode);
    //logger.i(r.body);

  } catch (e) {
    logWriter.writeLog(logFileName, 'SNOW', 'Error:${e.toString()}');
  }
}

void setSMAXAuth() async {
  var context = SecurityContext();
  context.setTrustedCertificates(smaxConfig.certFilePath);
  var smaxHttpClient = HttpClient(context: context);

  try {
    var request = await smaxHttpClient.postUrl(Uri.parse(smaxConfig.authUrl));
    var payload = {
      'Login': '${smaxConfig.uname}',
      'Password': '${smaxConfig.password}',
    };
    request.write(json.encode(payload));
    var response = await request.close();
    if (response.statusCode == 200) {
      var authToken = await response.transform(utf8.decoder).join();
      smaxConfig.authCookie = authToken;
      logger.i('SMAX Auth Successfull');
      logWriter.writeLog(
          logFileName, 'SMAX', 'SMAX Auth Successfull: Token \n ${authToken} ');
    } else {
      var erMsg = await response.transform(utf8.decoder).join();
      logger.i(
          'ERROR SMAX Auth Error: Status Code ${response.statusCode} Message \n ${erMsg} ');
      logWriter.writeLog(logFileName, 'SMAX',
          'ERROR SMAX Auth Error: Status Code ${response.statusCode} Message \n ${erMsg} ');
    }
  } catch (e) {
    logWriter.writeLog(logFileName, 'SMAX',
        'ERROR SMAX Create Bulk Error: Exception Occured \n ${e.toString()} ');
    logger.e(
        'ERROR SMAX Create Bulk Error: Exception Occured \n ${e.toString()} ');
  }
}

void sendToSMAX(payload, ticketType) async {
  var startDateTime = DateTime.now();
  var context = SecurityContext();
  context.setTrustedCertificates(smaxConfig.certFilePath);
  var smaxHttpClient = HttpClient(context: context);
  try {
    var request =
        await smaxHttpClient.postUrl(Uri.parse(smaxConfig.endpointUrl));
    request.headers.set('Cookie', 'LWSSO_COOKIE_KEY=${smaxConfig.authCookie}');
    request.write(payload);
    var response = await request.close();
    var endDateTime = DateTime.now();
    processedRecords.elapseTime =
        endDateTime.difference(startDateTime).inMilliseconds;
    if (response.statusCode == 200) {
      var responseJson = await response.transform(utf8.decoder).join();
      var responseJsonStr = jsonDecode(responseJson);
      // logger.i(responseJsonStr['entity_result_list'][0]['entity']['properties']['Id']);
      if (ticketType == 'ems') {
        processedRecords.smaxId = responseJsonStr['entity_result_list'][0]
            ['entity']['properties']['Id'];
        processedRecords.status = 'Success';
        smaxConfig.authUrl = responseJson;
        logger.i('SMAX Create Bulk Successfull');
        logWriter.writeLog(logFileName, 'SMAX',
            'SMAX Create Bulk Successfull: Response JSON \n ${responseJson} ');
        await mongoDB.createRecord(smaxConfig.endpointUrl, payload, 'SUCCESS',
            processedRecords.elapseTime, smaxConfig.smaxEntity);
      } else {
        processedRecords.smaxId = responseJsonStr['JobId'];
        processedRecords.status = 'Success';
        logger.i('SMAX Create Bulk Successfull');
        logWriter.writeLog(logFileName, 'SMAX',
            'SMAX Create Bulk Successfull: Response JSON \n ${responseJson} ');
        await mongoDB.createRecord(smaxConfig.endpointUrl, payload, 'SUCCESS',
            processedRecords.elapseTime, smaxConfig.smaxEntity);
      }
    } else {
      var erMsg = await response.transform(utf8.decoder).join();
      logger.i(
          'ERROR SMAX Create Bulk Error: Status Code ${response.statusCode} Message \n ${erMsg} ');
      processedRecords.status = 'Failed';
      logWriter.writeLog(logFileName, 'SMAX',
          'ERROR SMAX Create Bulk Error: Status Code ${response.statusCode} Message \n ${erMsg} ');
      await mongoDB.createRecord(smaxConfig.endpointUrl, payload, 'FAILED',
          processedRecords.elapseTime, smaxConfig.smaxEntity);
    }
  } catch (e) {
    logWriter.writeLog(logFileName, 'SMAX',
        'ERROR SMAX Create Bulk Error: Exception Occured \n ${e.toString()} ');
    logger.i(
        'ERROR SMAX Create Bulk Error: Exception Occured \n ${e.toString()} ');
    processedRecords.status = 'Failed';
    await mongoDB.createRecord(smaxConfig.endpointUrl, payload, 'FAILED',
        processedRecords.elapseTime, smaxConfig.smaxEntity);
  }
  logWriter.writeStatus();
}

String getSMAXImpact(sImpact) {
  return mappingConfig.jsonVals['Impact'][sImpact];
}

String getSMAXUrgency(sUrgency) {
  return mappingConfig.jsonVals['Urgency'][sUrgency];
}

Future<String> getSMAXService(sService, auth) async {
  var snowServiceName = await getSNOWServiceName(sService);
  if (snowServiceName != null) {
    //var response;
    var serviceUrl =
        '/ems/ActualService?filter=DisplayLabel+startswith+(%27${snowServiceName}%27)&layout=Id,DisplayLabel';
    var context = SecurityContext();
    context.setTrustedCertificates(smaxConfig.certFilePath);
    var smaxHttpClient = HttpClient(context: context);
    try {
      var request = await smaxHttpClient.getUrl(Uri.parse(
          'https://${smaxConfig.hostName}/rest/${smaxConfig.tenantId}${serviceUrl}'));
      request.headers
          .set('Cookie', 'LWSSO_COOKIE_KEY=${smaxConfig.authCookie}');
      var response = await request.close();
      if (response.statusCode == 200) {
        logger.i(
            'https://${smaxConfig.hostName}/rest/${smaxConfig.tenantId}${serviceUrl}');
        var smaxGetServiceResponse =
            jsonDecode(await response.transform(utf8.decoder).join());
        logger.i(smaxGetServiceResponse['meta']['completion_status']);
        if (smaxGetServiceResponse['meta']['completion_status'] == 'OK' &&
            smaxGetServiceResponse['meta']['total_count'] != 0) {
          return smaxGetServiceResponse['entities'][0]['properties']['Id'];
        } else {
          return smaxConfig.defaultServiceCode;
        }
      } else {
        return smaxConfig.defaultServiceCode;
      }
    } catch (e) {
      logger.e(e.toString());
      return smaxConfig.defaultServiceCode;
    }
  } else {
    return smaxConfig.defaultServiceCode;
  }
}

//TODO
Future<dynamic> getSNOWServiceName(snowServiceCode) async {
  try {
    var auth = 'Basic ' +
        base64Encode(utf8.encode('${snowConfig.uname}:${snowConfig.password}'));
    var r = await http.get(
        'https://${snowConfig.hostName}/api/now/table/cmdb_ci/${snowServiceCode}',
        headers: <String, String>{'authorization': auth});
    if (r.statusCode == 200) {
      var snowResponse = jsonDecode(r.body);
      logger.i(snowResponse['result']['name']);
      return snowResponse['result']['name'];
    } else {
      return null;
    }
  } catch (e) {
    logger.i(e.message);
    return null;
  }
}
