// LINT
void firstFunction(
  String firstArgument,
  String secondArgument,
  String thirdArgument,
) {
  return;
}

void secondFunction() {
  firstFunction(
    'some string',
    'some other string',
    'and another string for length exceed',
  ); // LINT
}

void thirdFunction(
  String someLongVarName,
  void Function() someLongCallbackName,
  String arg3,
) {} // LINT

class TestClass {
  // LINT
  void firstMethod(
    String firstArgument,
    String secondArgument,
    String thirdArgument,
  ) {
    return;
  }

  void secondMethod() {
    firstMethod(
      'some string',
      'some other string',
      'and another string for length exceed',
    ); // LINT

    thirdFunction(
      'some string',
      () {
        return;
      },
      'some other string',
    ); // LINT
  }
}

enum FirstEnum {
  firstItem,
  secondItem,
  thirdItem,
  forthItem,
  fifthItem,
  sixthItem, // LINT
}

class FirstClass {
  // LINT
  const FirstClass(
    this.firstField,
    this.secondField,
    this.thirdField,
    this.forthField,
  );

  final num firstField;
  final num secondField;
  final num thirdField;
  final num forthField;
}

const FirstClass instance = FirstClass(
  3.14159265359,
  3.14159265359,
  3.14159265359,
  3.14159265359,
);

final List<String> secondArray = <String>[
  'some string',
  'some other string',
  'and another string for length exceed', // LINT
];

final Set<String> secondSet = <String>{
  'some string',
  'some other string',
  'and another string for length exceed', // LINT
};

final Map<String, String> secondMap = <String, String>{
  'some string': 'and another string for length exceed',
  // LINT
  'and another string for length exceed':
      'and another string for length exceed___________________________________________',
};

enum FirstEnum2 {
  firstItem,
  secondItem,
  thirdItem,
  forthItem,
  fifthItem,
  // ignore: prefer_trailing_comma
  sixthItem // LINT
}
