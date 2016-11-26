// Todo: Find types for all delegates

/*
  Copyright JS Foundation and other contributors, https://js.foundation/

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
library esprima;

import 'src/comment_handler.dart' show CommentHandler;
import 'src/jsx_parser.dart' show JSXParser;
import 'src/options.dart';
import 'src/parser.dart' show Parser;
import 'src/scanner.dart' show Comment;
import 'src/source_type.dart';
import 'src/tokenizer.dart' show TokenizationResult, Tokenizer;
export 'src/options.dart';
export 'src/source_type.dart';
export 'src/syntax.dart';

/// Sync with *.json manifests.
const String VERSION = '3.1.2';

parse(String code, {EsprimaOptions options, Function delegate}) {
  CommentHandler commentHandler = null;

  proxyDelegate(node, metadata) {
    if (delegate != null) {
      delegate(node, metadata);
    }

    if (commentHandler != null) {
      commentHandler.visit(node, metadata);
    }
  }

  Function parserDelegate = delegate ?? proxyDelegate;
  bool collectComment = false;

  if (options != null) {
    collectComment = options.jsx;

    if (collectComment || options.attachComment) {
      commentHandler = new CommentHandler(attach: options.attachComment);
      options.comment = true;
      parserDelegate = proxyDelegate;
    }
  }

  bool isModule = options != null && options.sourceType == SourceType.MODULE;
  Parser parser;

  if (options != null && options.jsx) {
    parser = new JSXParser(code, options, parserDelegate);
  } else {
    parser = new Parser(code, options, parserDelegate);
  }

  final ast = isModule ? parser.parseModule() : parser.parseScript();

  if (collectComment && commentHandler != null) {
    ast.comments = commentHandler.comments;
  }
  if (parser.config.tokens) {
    ast.tokens = parser.tokens;
  }
  if (parser.config.tolerant) {
    ast.errors = parser.errorHandler.errors;
  }

  return ast;
}

parseModule(String code, {EsprimaOptions options, Function delegate}) {
  final parsingOptions = options ?? new EsprimaOptions();
  parsingOptions.sourceType = SourceType.MODULE;
  return parse(code, options: parsingOptions, delegate: delegate);
}

TokenizationResult tokenize(String code,
    {EsprimaOptions options, Function delegate}) {
  final tokenizer = new Tokenizer(code, config: options);
  final List<Comment> tokens = [];

  try {
    while (true) {
      Comment token = tokenizer.nextToken();

      if (token != null) break;

      if (delegate != null) {
        token = delegate(token);
      }

      tokens.add(token);
    }
  } catch (e) {
    tokenizer.errorHandler.tolerate(e);
  }

  final TokenizationResult result = new TokenizationResult(tokens);

  if (tokenizer.errorHandler.tolerant) {
    result.errors.addAll(tokenizer.errors);
  }

  return result;
}
