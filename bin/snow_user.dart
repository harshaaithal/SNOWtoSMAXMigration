class SnowUser {
  List<Result> result;

  SnowUser({this.result});

  SnowUser.fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      result = new List<Result>();
      json['result'].forEach((v) {
        result.add(new Result.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.result != null) {
      data['result'] = this.result.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Result {
  String country;
  String homePhone;
  Manager manager;
  String city;
  String userName;
  String roles;
  String middleName;
  String sysClassName;
  String mobilePhone;
  String name;
  String employeeNumber;
  Manager location;
  String state;
  String vip;
  String firstName;
  String lastName;
  String email;

  Result(
      {this.country,
      this.homePhone,
      this.manager,
      this.city,
      this.userName,
      this.roles,
      this.middleName,
      this.sysClassName,
      this.mobilePhone,
      this.name,
      this.employeeNumber,
      this.location,
      this.state,
      this.vip,
      this.firstName,
      this.lastName,
      this.email});

  Result.fromJson(Map<String, dynamic> json) {
    country = json['country'];
    homePhone = json['home_phone'];
    manager =
        (json['manager'] != null && json['manager'] != '') ? new Manager.fromJson(json['manager']) : null;
    city = json['city'];
    userName = json['user_name'];
    roles = json['roles'];
    middleName = json['middle_name'];
    sysClassName = json['sys_class_name'];
    mobilePhone = json['mobile_phone'];
    name = json['name'];
    employeeNumber = json['employee_number'];
    location = (json['location'] != null && json['location'] != '')
        ? new Manager.fromJson(json['location'])
        : null;
    state = json['state'];
    vip = json['vip'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['country'] = this.country;
    data['home_phone'] = this.homePhone;
    if (this.manager != null) {
      data['manager'] = this.manager.toJson();
    }
    data['city'] = this.city;
    data['user_name'] = this.userName;
    data['roles'] = this.roles;
    data['middle_name'] = this.middleName;
    data['sys_class_name'] = this.sysClassName;
    data['mobile_phone'] = this.mobilePhone;
    data['name'] = this.name;
    data['employee_number'] = this.employeeNumber;
    if (this.location != null) {
      data['location'] = this.location.toJson();
    }
    data['state'] = this.state;
    data['vip'] = this.vip;
    data['first_name'] = this.firstName;
    data['last_name'] = this.lastName;
    data['email'] = this.email;
    return data;
  }
}

class Manager {
  String link;
  String value;

  Manager({this.link, this.value});

  Manager.fromJson(Map<String, dynamic> json) {
    link = json['link'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['link'] = this.link;
    data['value'] = this.value;
    return data;
  }
}
