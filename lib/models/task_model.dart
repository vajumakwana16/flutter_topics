class Task {
  String title;
  String? subTitle;
  bool isDone;

  Task(this.title, this.subTitle, this.isDone);

  Task copyWith({String? title, String? subTitle, bool? isDone}) {
    return Task(
      title ?? this.title,
      subTitle ?? this.subTitle,
      isDone ?? this.isDone,
    );
  }
}