class SnowGroup {
  List<Result> result;

  SnowGroup({this.result});

  SnowGroup.fromJson(Map<String, dynamic> json) {
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
  Manager manager;
  String name;
  String type;
  String email;

  Result({this.manager, this.name, this.type, this.email});

  Result.fromJson(Map<String, dynamic> json) {
    manager = json['manager'] != null && json['manager'] != ''
        ? new Manager.fromJson(json['manager'])
        : null;
    name = json['name'];
    type = json['type'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.manager != null) {
      data['manager'] = this.manager.toJson();
    }
    data['name'] = this.name;
    data['type'] = this.type;
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
