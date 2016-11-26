// Todo: Find default options
class EsprimaOptions {
  bool attachComment, comment, jsx, loc, range, tolerant;
  String sourceType;

  EsprimaOptions(
      {this.attachComment,
      this.comment,
      this.jsx,
      this.loc,
      this.range,
      this.sourceType,
      this.tolerant});
}
