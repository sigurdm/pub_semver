// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:pub_semver/pub_semver.dart';

import 'utils.dart';

main() {
  test('none', () {
    expect(Version.none.toString(), equals('0.0.0'));
  });

  test('prioritize()', () {
    // A correctly sorted list of versions in order of increasing priority.
    var versions = [
      '1.0.0-alpha',
      '2.0.0-alpha',
      '1.0.0',
      '1.0.0+build',
      '1.0.1',
      '1.1.0',
      '2.0.0'
    ];

    // Ensure that every pair of versions is prioritized in the order that it
    // appears in the list.
    for (var i = 0; i < versions.length; i++) {
      for (var j = 0; j < versions.length; j++) {
        var a = new Version.parse(versions[i]);
        var b = new Version.parse(versions[j]);
        expect(Version.prioritize(a, b), equals(i.compareTo(j)));
      }
    }
  });

  test('antiprioritize()', () {
    // A correctly sorted list of versions in order of increasing antipriority.
    var versions = [
      '2.0.0-alpha',
      '1.0.0-alpha',
      '2.0.0',
      '1.1.0',
      '1.0.1',
      '1.0.0+build',
      '1.0.0'
    ];

    // Ensure that every pair of versions is prioritized in the order that it
    // appears in the list.
    for (var i = 0; i < versions.length; i++) {
      for (var j = 0; j < versions.length; j++) {
        var a = new Version.parse(versions[i]);
        var b = new Version.parse(versions[j]);
        expect(Version.antiprioritize(a, b), equals(i.compareTo(j)));
      }
    }
  });

  group('constructor', () {
    test('throws on negative numbers', () {
      expect(() => new Version(-1, 1, 1), throwsArgumentError);
      expect(() => new Version(1, -1, 1), throwsArgumentError);
      expect(() => new Version(1, 1, -1), throwsArgumentError);
    });
  });

  group('comparison', () {
    // A correctly sorted list of versions.
    var versions = [
      '1.0.0-alpha',
      '1.0.0-alpha.1',
      '1.0.0-beta.2',
      '1.0.0-beta.11',
      '1.0.0-rc.1',
      '1.0.0-rc.1+build.1',
      '1.0.0',
      '1.0.0+0.3.7',
      '1.3.7+build',
      '1.3.7+build.2.b8f12d7',
      '1.3.7+build.11.e0f985a',
      '2.0.0',
      '2.1.0',
      '2.2.0',
      '2.11.0',
      '2.11.1'
    ];

    test('compareTo()', () {
      // Ensure that every pair of versions compares in the order that it
      // appears in the list.
      for (var i = 0; i < versions.length; i++) {
        for (var j = 0; j < versions.length; j++) {
          var a = new Version.parse(versions[i]);
          var b = new Version.parse(versions[j]);
          expect(a.compareTo(b), equals(i.compareTo(j)));
        }
      }
    });

    test('operators', () {
      for (var i = 0; i < versions.length; i++) {
        for (var j = 0; j < versions.length; j++) {
          var a = new Version.parse(versions[i]);
          var b = new Version.parse(versions[j]);
          expect(a < b, equals(i < j));
          expect(a > b, equals(i > j));
          expect(a <= b, equals(i <= j));
          expect(a >= b, equals(i >= j));
          expect(a == b, equals(i == j));
          expect(a != b, equals(i != j));
        }
      }
    });

    test('equality', () {
      expect(new Version.parse('01.2.3'), equals(new Version.parse('1.2.3')));
      expect(new Version.parse('1.02.3'), equals(new Version.parse('1.2.3')));
      expect(new Version.parse('1.2.03'), equals(new Version.parse('1.2.3')));
      expect(new Version.parse('1.2.3-01'),
          equals(new Version.parse('1.2.3-1')));
      expect(new Version.parse('1.2.3+01'),
          equals(new Version.parse('1.2.3+1')));
    });
  });

  test('allows()', () {
    expect(v123, allows(v123));
    expect(v123, doesNotAllow(
        new Version.parse('2.2.3'),
        new Version.parse('1.3.3'),
        new Version.parse('1.2.4'),
        new Version.parse('1.2.3-dev'),
        new Version.parse('1.2.3+build')));
  });

  test('allowsAll()', () {
    expect(v123.allowsAll(v123), isTrue);
    expect(v123.allowsAll(v003), isFalse);
    expect(v123.allowsAll(new VersionRange(min: v114, max: v124)), isFalse);
    expect(v123.allowsAll(VersionConstraint.any), isFalse);
    expect(v123.allowsAll(VersionConstraint.empty), isTrue);
  });

  test('allowsAny()', () {
    expect(v123.allowsAny(v123), isTrue);
    expect(v123.allowsAny(v003), isFalse);
    expect(v123.allowsAny(new VersionRange(min: v114, max: v124)), isTrue);
    expect(v123.allowsAny(VersionConstraint.any), isTrue);
    expect(v123.allowsAny(VersionConstraint.empty), isFalse);
  });

  test('intersect()', () {
    // Intersecting the same version returns the version.
    expect(v123.intersect(v123), equals(v123));

    // Intersecting a different version allows no versions.
    expect(v123.intersect(v114).isEmpty, isTrue);

    // Intersecting a range returns the version if the range allows it.
    expect(v123.intersect(new VersionRange(min: v114, max: v124)),
        equals(v123));

    // Intersecting a range allows no versions if the range doesn't allow it.
    expect(v114.intersect(new VersionRange(min: v123, max: v124)).isEmpty,
        isTrue);
  });

  group('union()', () {
    test("with the same version returns the version", () {
      expect(v123.union(v123), equals(v123));
    });

    test("with a different version returns a version that matches both", () {
      var result = v123.union(v080);
      expect(result, allows(v123));
      expect(result, allows(v080));

      // Nothing in between should match.
      expect(result, doesNotAllow(v114));
    });

    test("with a range returns the range if it contains the version", () {
      var range = new VersionRange(min: v114, max: v124);
      expect(v123.union(range), equals(range));
    });

    test("with a range with the version on the edge, expands the range", () {
      expect(v124.union(new VersionRange(min: v114, max: v124)),
          equals(new VersionRange(min: v114, max: v124, includeMax: true)));
      expect(v114.union(new VersionRange(min: v114, max: v124)),
          equals(new VersionRange(min: v114, max: v124, includeMin: true)));
    });

    test("with a range allows both the range and the version if the range "
        "doesn't contain the version", () {
      var result = v123.union(new VersionRange(min: v003, max: v114));
      expect(result, allows(v123));
      expect(result, allows(v010));
    });
  });

  group('difference()', () {
    test("with the same version returns an empty constraint", () {
      expect(v123.difference(v123), isEmpty);
    });

    test("with a different version returns the original version", () {
      expect(v123.difference(v080), equals(v123));
    });

    test("returns an empty constraint with a range that contains the version",
        () {
      expect(v123.difference(new VersionRange(min: v114, max: v124)), isEmpty);
    });

    test("returns the version constraint with a range that doesn't contain it",
        () {
      expect(v123.difference(new VersionRange(min: v140, max: v300)),
          equals(v123));
    });
  });

  test('isEmpty', () {
    expect(v123.isEmpty, isFalse);
  });

  test('nextMajor', () {
    expect(v123.nextMajor, equals(v200));
    expect(v114.nextMajor, equals(v200));
    expect(v200.nextMajor, equals(v300));

    // Ignores pre-release if not on a major version.
    expect(new Version.parse('1.2.3-dev').nextMajor, equals(v200));

    // Just removes it if on a major version.
    expect(new Version.parse('2.0.0-dev').nextMajor, equals(v200));

    // Strips build suffix.
    expect(new Version.parse('1.2.3+patch').nextMajor, equals(v200));
  });

  test('nextMinor', () {
    expect(v123.nextMinor, equals(v130));
    expect(v130.nextMinor, equals(v140));

    // Ignores pre-release if not on a minor version.
    expect(new Version.parse('1.2.3-dev').nextMinor, equals(v130));

    // Just removes it if on a minor version.
    expect(new Version.parse('1.3.0-dev').nextMinor, equals(v130));

    // Strips build suffix.
    expect(new Version.parse('1.2.3+patch').nextMinor, equals(v130));
  });

  test('nextPatch', () {
    expect(v123.nextPatch, equals(v124));
    expect(v200.nextPatch, equals(v201));

    // Just removes pre-release version if present.
    expect(new Version.parse('1.2.4-dev').nextPatch, equals(v124));

    // Strips build suffix.
    expect(new Version.parse('1.2.3+patch').nextPatch, equals(v124));
  });

  test('nextBreaking', () {
    expect(v123.nextBreaking, equals(v200));
    expect(v072.nextBreaking, equals(v080));
    expect(v003.nextBreaking, equals(v010));

    // Removes pre-release version if present.
    expect(new Version.parse('1.2.3-dev').nextBreaking, equals(v200));

    // Strips build suffix.
    expect(new Version.parse('1.2.3+patch').nextBreaking, equals(v200));
  });

  test('parse()', () {
    expect(new Version.parse('0.0.0'), equals(new Version(0, 0, 0)));
    expect(new Version.parse('12.34.56'), equals(new Version(12, 34, 56)));

    expect(new Version.parse('1.2.3-alpha.1'),
        equals(new Version(1, 2, 3, pre: 'alpha.1')));
    expect(new Version.parse('1.2.3-x.7.z-92'),
        equals(new Version(1, 2, 3, pre: 'x.7.z-92')));

    expect(new Version.parse('1.2.3+build.1'),
        equals(new Version(1, 2, 3, build: 'build.1')));
    expect(new Version.parse('1.2.3+x.7.z-92'),
        equals(new Version(1, 2, 3, build: 'x.7.z-92')));

    expect(new Version.parse('1.0.0-rc-1+build-1'),
        equals(new Version(1, 0, 0, pre: 'rc-1', build: 'build-1')));

    expect(() => new Version.parse('1.0'), throwsFormatException);
    expect(() => new Version.parse('1.2.3.4'), throwsFormatException);
    expect(() => new Version.parse('1234'), throwsFormatException);
    expect(() => new Version.parse('-2.3.4'), throwsFormatException);
    expect(() => new Version.parse('1.3-pre'), throwsFormatException);
    expect(() => new Version.parse('1.3+build'), throwsFormatException);
    expect(() => new Version.parse('1.3+bu?!3ild'), throwsFormatException);
  });

  group('toString()', () {
    test('returns the version string', () {
      expect(new Version(0, 0, 0).toString(), equals('0.0.0'));
      expect(new Version(12, 34, 56).toString(), equals('12.34.56'));

      expect(new Version(1, 2, 3, pre: 'alpha.1').toString(),
          equals('1.2.3-alpha.1'));
      expect(new Version(1, 2, 3, pre: 'x.7.z-92').toString(),
          equals('1.2.3-x.7.z-92'));

      expect(new Version(1, 2, 3, build: 'build.1').toString(),
          equals('1.2.3+build.1'));
      expect(new Version(1, 2, 3, pre: 'pre', build: 'bui').toString(),
          equals('1.2.3-pre+bui'));
    });

    test('preserves leading zeroes', () {
      expect(new Version.parse('001.02.0003-01.dev+pre.002').toString(),
          equals('001.02.0003-01.dev+pre.002'));
    });
  });
}
