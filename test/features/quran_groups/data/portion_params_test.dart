import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/quran/portion_unit.dart';
import 'package:quran_daily/features/quran_groups/data/data_sources/groups_remote_data_source.dart';
import 'package:quran_daily/features/quran_groups/data/entities/entities.dart';
import 'package:quran_daily/features/quran_groups/data/repositories/groups_repository.dart';

void main() {
  test('create group sends portion unit, defaulting to juz', () {
    const input = CreateGroupInput(
      name: 'circle',
      timezone: 'Africa/Cairo',
      visibility: GroupVisibility.private,
      joinMode: JoinMode.approval,
      portionUnit: PortionUnit.hizb,
    );
    expect(GroupsParams.createGroup(input)['p_portion_unit'], 'hizb');
    expect(
      GroupsParams.createGroup(
        const CreateGroupInput(
          name: 'circle',
          timezone: 'Africa/Cairo',
          visibility: GroupVisibility.private,
          joinMode: JoinMode.approval,
        ),
      )['p_portion_unit'],
      'juz',
    );
  });

  test('start khatma sends start portion parameter', () {
    expect(GroupsParams.startKhatma('g1', 42), {
      'p_group_id': 'g1',
      'p_start_portion': 42,
    });
  });

  test('settings patch sends portion unit only when supplied', () {
    expect(
      GroupsParams.updateGroupSettings(
        'g1',
        const GroupSettingsPatch(portionUnit: PortionUnit.quarter),
      )['p_portion_unit'],
      'quarter',
    );
    expect(
      GroupsParams.updateGroupSettings(
        'g1',
        const GroupSettingsPatch(),
      ).containsKey('p_portion_unit'),
      isFalse,
    );
  });
}
