const classDurationOptions = <String>[
  '45',
  '60',
  '90',
  '120',
  '165',
  '180',
  '210',
];

int parseClassDurationMinutes(String value) {
  if (!classDurationOptions.contains(value)) return 60;
  return int.parse(value);
}

String normalizeClassStatus(Object? value) {
  return (value ?? 'activa').toString().trim().toLowerCase();
}

bool classCanBeModified(Object? status) {
  return normalizeClassStatus(status) == 'activa';
}

bool classDeletionNameMatches({
  required String expectedName,
  required String enteredName,
}) {
  return enteredName.trim() == expectedName.trim();
}
