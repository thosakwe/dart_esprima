// Todo: Find default options
class EsprimaOptions {
  bool attachComment, comment, jsx, loc, range, tolerant, tokens;
  String source, sourceType;

  EsprimaOptions(
      {this.attachComment,
      this.comment,
      this.jsx,
      this.loc,
      this.range,
      this.source,
      this.sourceType,
      this.tolerant,
      this.tokens});
}
