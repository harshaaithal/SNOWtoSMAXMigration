class SmaxPerson {
  String operation;
  List<Users> users;

  SmaxPerson({this.operation, this.users});

  SmaxPerson.fromJson(Map<String, dynamic> json) {
    operation = json['operation'];
    if (json['users'] != null) {
      users = <Users>[];
      json['users'].forEach((v) {
        users.add(Users.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['operation'] = this.operation ?? this.operation;
    if (this.users != null) {
      data['users'] = this.users ?? this.users.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Users {
  Properties properties;
  String upnDataType;
  Roles roles;
  Roles groups;

  Users({this.properties, this.upnDataType, this.roles, this.groups});

  Users.fromJson(Map<String, dynamic> json) {
    properties = json['properties'] != null
        ? Properties.fromJson(json['properties'])
        : null;
    upnDataType = json['upnDataType'];
    roles = json['roles'] != null ? Roles.fromJson(json['roles']) : null;
    groups = json['groups'] != null ? Roles.fromJson(json['groups']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.properties != null) {
      data['properties'] = this.properties ?? this.properties.toJson();
    }
    data['upnDataType'] = this.upnDataType ?? this.upnDataType;
    if (this.roles != null) {
      data['roles'] = this.roles ?? this.roles.toJson();
    }
    if (this.groups != null) {
      data['groups'] = this.groups ?? this.groups.toJson();
    }
    return data;
  }
}

class Properties {
  String firstName;
  String lastName;
  String officePhoneNumber;
  String mobilePhoneNumber;
  String homePhoneNumber;
  String upn;
  String manager;
  String isMaasUser;
  String location;
  String costCenter;
  String email;
  String authenticationType;

  Properties(
      {this.firstName,
      this.lastName,
      this.officePhoneNumber,
      this.mobilePhoneNumber,
      this.homePhoneNumber,
      this.upn,
      this.manager,
      this.isMaasUser,
      this.location,
      this.costCenter,
      this.email,
      this.authenticationType});

  Properties.fromJson(Map<String, dynamic> json) {
    firstName = json['FirstName'];
    lastName = json['LastName'];
    officePhoneNumber = json['OfficePhoneNumber'];
    mobilePhoneNumber = json['MobilePhoneNumber'];
    homePhoneNumber = json['HomePhoneNumber'];
    upn = json['Upn'];
    manager = json['Manager'];
    isMaasUser = json['IsMaasUser'];
    location = json['Location'];
    costCenter = json['CostCenter'];
    email = json['Email'];
    authenticationType = json['AuthenticationType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['FirstName'] = this.firstName ?? this.firstName;
    data['LastName'] = this.lastName ?? this.lastName;
    data['OfficePhoneNumber'] =
        this.officePhoneNumber ?? this.officePhoneNumber;
    data['MobilePhoneNumber'] =
        this.mobilePhoneNumber ?? this.mobilePhoneNumber;
    data['HomePhoneNumber'] = this.homePhoneNumber ?? this.homePhoneNumber;
    data['Upn'] = this.upn ?? this.upn;
    data['Manager'] = this.manager ?? this.manager;
    data['IsMaasUser'] = this.isMaasUser ?? this.isMaasUser;
    data['Location'] = this.location ?? this.location;
    data['CostCenter'] = this.costCenter ?? this.costCenter;
    data['Email'] = this.email ?? this.email;
    data['AuthenticationType'] =
        this.authenticationType ?? this.authenticationType;
    return data;
  }
}

class Roles {
  List<String> rEPLACE;

  Roles({this.rEPLACE});

  Roles.fromJson(Map<String, dynamic> json) {
    rEPLACE = json['REPLACE'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['REPLACE'] = this.rEPLACE ?? this.rEPLACE;
    return data;
  }
}
