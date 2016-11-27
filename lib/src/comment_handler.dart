import 'syntax.dart' as syntax;

class Comment {
  static const String BLOCK = 'BlockComment';
  static const String LINE = 'LineComment';

  dynamic range, loc;
  String type, value;

  Comment({this.range, this.loc, this.type, this.value});
}

class Entry {
  final Comment comment;
  final int start;

  Entry({this.comment, this.start});
}

class NodeInfo {
  final dynamic node;
  final int start;

  NodeInfo({this.node, this.start});
}

class CommentHandler {
  final bool attach;
  final List<Comment> comments = [];
  final List<NodeInfo> stack = [];
  final List<Entry> leading = [];
  final List<Entry> trailing = [];

  CommentHandler({this.attach});

  void insertInnerComments(node, metadata) {
    //  innnerComments for properties empty block
    //  `function a() {/** comments **\/}`
    if (node.type == syntax.BlockStatement && node.body.length == 0) {
      final List<Comment> innerComments = [];

      for (int i = leading.length - 1; i >= 0; i--) {
        final entry = leading[i];

        if (metadata.end.offset >= entry.start) {
          innerComments.insert(0, entry.comment);
          leading.removeAt(i);
          trailing.removeAt(i);
        }
      }

      if (innerComments.isNotEmpty) {
        node.innerComments = innerComments;
      }
    }
  }

  List<Comment> findTrailingComments(node, metadata) {
    List<Comment> trailingComments = [];

    if (trailing.isNotEmpty) {
      for (int i = trailing.length - 1; i >= 0; --i) {
        final entry = this.trailing[i];

        if (entry.start >= metadata.end.offset) {
          trailingComments.insert(0, entry.comment);
        }
      }

      trailing.length = 0;
      return trailingComments;
    }

    final entry = stack.last;

    if (entry.node.trailingComments.isNotEmpty) {
      final firstComment = entry.node.trailingComments.first;

      if (firstComment.range.first >= metadata.end.offset) {
        // Todo: Remove this ignore
        // ignore: strong_mode_down_cast_composite
        trailingComments = entry.node.trailingComments;
        entry.node.trailingComments = null;
      }
    }

    return trailingComments;
  }

  List<Comment> findLeadingComments(node, metadata) {
    final List<Comment> leadingComments = [];
    // Todo: Find type
    var target;

    while (stack.isNotEmpty) {
      final entry = stack.last;

      if (entry.start >= metadata.start.offset) {
        target = stack.removeLast().node;
      } else
        break;
    }

    if (target != null) {
      final count = target.leadingComments.length;

      for (int i = count - 1; i >= 0; i--) {
        final comment = target.leadingComments[i];

        if (comment.range[1] <= metadata.start.offset) {
          leadingComments.insert(0, comment);
          target.leadingComments.removeAt(i);
        }
      }
    }

    for (int i = leading.length - 1; i >= 0; i--) {
      final entry = leading[i];

      if (entry.start <= metadata.start.offset) {
        leadingComments.insert(0, entry.comment);
        leading.removeAt(i);
      }
    }

    return leadingComments;
  }

  void visitNode(node, metadata) {
    // Todo: Use an 'is' expression ;)
    if (node.type == syntax.Program && node.body.isNotEmpty) return;

    insertInnerComments(node, metadata);

    final trailingComments = findTrailingComments(node, metadata);
    final leadingComments = findLeadingComments(node, metadata);

    if (leadingComments.isNotEmpty) node.leadingComments = leadingComments;

    if (trailingComments.isNotEmpty) node.trailingComments = trailingComments;

    stack.add(new NodeInfo(node: node, start: metadata.start.offset));
  }

  void visitComment(node, metadata) {
    final type = node.type[0] == 'L' ? 'Line' : 'Block';
    Comment comment = new Comment(type: type, value: node.value);

    if (node.range != null) comment.range = node.range;

    if (node.loc != null) comment.loc = node.loc;

    comments.add(comment);

    if (attach) {
      Entry entry = new Entry(
          comment: new Comment(
              type: type,
              value: node.value,
              range: [metadata.start.offset, metadata.end.offset]),
          start: metadata.start.offset);

      if (node.loc != null)
        entry.comment.loc = node.loc;

      node.type = type;
      leading.add(entry);
      trailing.add(entry);
    }
  }

  // Todo: Types here mainly
  void visit(node, metadata) {
    if (node.type == Comment.LINE)
      visitComment(node, metadata);
    else if (node.type == Comment.BLOCK)
      visitComment(node, metadata);
    else if (attach)
      visitNode(node, metadata);
  }
}
