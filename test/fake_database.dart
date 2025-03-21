/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:matrix/matrix.dart';

Future<DatabaseApi> getDatabase(Client? c, {String? databasePath}) =>
    getMatrixSdkDatabase(c, path: databasePath);

// ignore: deprecated_member_use_from_same_package
Future<MatrixSdkDatabase> getMatrixSdkDatabase(
  Client? c, {
  String? path,
}) async {
  final database = await databaseFactoryFfi.openDatabase(
    path ?? ':memory:',
    options: OpenDatabaseOptions(singleInstance: false),
  );
  final db = MatrixSdkDatabase(
    'unit_test.${c?.hashCode}',
    database: database,
    sqfliteFactory: databaseFactoryFfi,
  );
  await db.open();
  return db;
}
