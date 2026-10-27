import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/features/academics/domain/models.dart';
import 'package:hyzen_pharmd/features/admin/domain/import_csv.dart';

const header =
    'kind,professional_year,semester,subject,section,topic,title,url,published\n';
void main() {
  test('CSV handles BOM, escaped quotes, commas and multiline values', () {
    final rows = parseCsv('\uFEFFa,b\r\n"one, two","He said ""Hi""\nnext"\r\n');
    expect(rows, [
      ['a', 'b'],
      ['one, two', 'He said "Hi"\nnext'],
    ]);
  });
  test('rejects unclosed quotes and repeated headers', () {
    expect(() => parseCsv('a,b\n"unterminated'), throwsException);
    expect(validateImport('kind,kind\nnotes,notes', 'bad.csv').valid, isFalse);
  });
  test('template placeholder cannot be imported', () {
    expect(
      validateImport(csvTemplate, 'template.csv').errors.join(),
      contains('Replace the example'),
    );
  });
  test('validates HTTPS, library kinds and publication flags', () {
    final good = validateImport(
      '${header}special,3rd Professional,Semester 1,Microbiology,Books,Bacteria,Book,https://example.org/book.pdf,false',
      'books.csv',
    );
    expect(good.valid, isTrue);
    expect(good.rows.single.kind, LibraryKind.special);
    expect(good.rows.single.published, isFalse);
    expect(
      validateImport(
        '${header}bad,Year,Semester,Subject,Notes,Topic,File,http://example.org/a.pdf,maybe',
        'bad.csv',
      ).errors.length,
      3,
    );
  });
  test('oversized CSV is rejected before constructing import rows', () {
    final text =
        header +
        List.filled(
          2001,
          'notes,Year,Semester,Subject,Notes,Topic,File,https://example.org/a.pdf,true',
        ).join('\n');
    final result = validateImport(text, 'large.csv');
    expect(result.rows, isEmpty);
    expect(result.errors.single, contains('2,000'));
  });
  test('merge retains existing IDs and private/unpublished properties', () {
    final input = <Map<String, dynamic>>[
      {
        'id': 'year-keep',
        'label': '2nd Professional',
        'custom': 'keep',
        'published': false,
        'semesters': <Map<String, dynamic>>[],
      },
    ];
    final tree = copyTree(input, LibraryKind.notes);
    final rows = validateImport(
      '${header}notes,2nd Professional,Semester 1,Pharmacology,Notes,Diabetes,Insulin,https://drive.google.com/file/d/FILE1/view,true',
      'a.csv',
    ).rows;
    var id = 0;
    final result = mergeRows(tree, rows, () => 'id-${id++}');
    expect(result.added, 1);
    expect(tree.single['id'], 'year-keep');
    expect(tree.single['custom'], 'keep');
    expect(tree.single['published'], isFalse);
    expect(
      input.single['semesters'],
      isEmpty,
    ); // Read/preview never mutates original.
    expect(mergeRows(tree, rows, () => 'id-${id++}').skipped, 1);
  });
  test('duplicate Drive links with different URL formats are skipped', () {
    final text =
        '${header}papers,2nd Professional,Semester 1,Pharmacology,UET,2025,Annual,https://drive.google.com/file/d/FILE1/view,true\n'
        'papers,2nd Professional,Semester 1,Pharmacology,UET,2025,Annual Copy,https://drive.google.com/open?id=FILE1,true';
    final rows = validateImport(text, 'papers.csv').rows;
    var id = 0;
    final tree = <Map<String, dynamic>>[];
    final result = mergeRows(tree, rows, () => 'id-${id++}');
    expect(result.added, 1);
    expect(result.skipped, 1);
    expect(Library.parse(LibraryKind.papers, tree).fileCount, 1);
  });
  test('hidden year/semester/subject content does not appear for students', () {
    var id = 0;
    final tree = <Map<String, dynamic>>[];
    mergeRows(
      tree,
      validateImport(
        '${header}notes,Year,Semester,Subject,Notes,Topic,File,https://example.org/a.pdf,true',
        'a.csv',
      ).rows,
      () => 'id-${id++}',
    );
    expect(Library.parse(LibraryKind.notes, tree).fileCount, 1);
    childrenAt(tree, ['id-0', 'id-1']).single['published'] = false;
    expect(Library.parse(LibraryKind.notes, tree).fileCount, 0);
  });
}
