# Task Repeat Count Design

## Goal

为 `Today` 任务增加有限重复次数能力，使 `daily` 与 `weekly` 任务都可以设置“总共重复 N 次”，并且该次数包含当前这条任务本身。

## Context

当前任务系统已经支持 `none / daily / weekly` 三种重复规则，也已经有基于完成事件自动生成 successor 的逻辑，但缺少“有限次数”这个约束，因此所有重复任务都会无限延续。用户希望可以创建诸如“日重复共 13 次”或“每周重复共 13 次”的任务，并在 `Today` 页面看到剩余次数。

## Chosen Approach

本次采用“总次数 + 剩余次数”双字段方案。`repeatTotalCount` 记录用户定义的整个重复序列总次数，`repeatRemainingCount` 记录当前这条任务在内还剩多少次。这样创建时语义清晰，完成任务时递减逻辑直接，且不需要跨整个 recurrence series 重新统计已完成条目。

## Data Model

- 在 `FocusTask` 中新增：
  - `repeatTotalCount: Int?`
  - `repeatRemainingCount: Int?`
- 在 `StoredTask` 中新增对应持久化字段，并保持对旧数据的兼容：
  - 非重复任务保持 `nil`
  - 历史无限重复任务保持 `nil`
- `repeatRule == .none` 时，这两个字段都应清空。

## Behavior

### Composer

- 当 `Repeat` 为 `None` 时，不显示次数输入。
- 当 `Repeat` 为 `Daily` 或 `Weekly` 时，显示 `Repeat count` 输入框。
- 输入值必须为正整数，最小为 `1`。
- 若用户输入 `13`，创建后的当前任务应保存为：
  - `repeatTotalCount = 13`
  - `repeatRemainingCount = 13`

### Completion

- 当重复任务完成时：
  - 若 `repeatRemainingCount == nil`，保持现有无限重复逻辑。
  - 若 `repeatRemainingCount > 1`，创建 successor，并把 successor 的 `repeatRemainingCount` 设为当前值减 `1`。
  - 若 `repeatRemainingCount == 1`，本次完成后不再生成 successor。
- successor 需继续保留：
  - `repeatRule`
  - `repeatWeekday`
  - `repeatTotalCount`
  - `linkedSubtaskID`
  - `contributionValue`
  - `recurrenceSeriesID`

## Today Presentation

- 在 `Today` 任务列表中，为有限重复任务显示轻量重复信息：
  - `Daily · 13 left`
  - `Weekly · Friday · 6 left`
- 无限重复任务继续只显示规则，不显示剩余次数。
- 非重复任务不显示这行信息。

## Validation Rules

- `repeatRule == .none` 时，不允许残留 `repeatTotalCount` 与 `repeatRemainingCount`。
- `repeatRule != .none` 且用户启用了有限次数时，`repeatTotalCount >= 1` 且 `repeatRemainingCount >= 1`。
- 编辑任务时，若从重复改为不重复，需要清空所有重复次数字段。

## Testing

- 持久化测试：确认有限重复次数可以 round-trip。
- ViewModel 测试：确认 composer 可保存有限重复次数，且非法输入会被拦截。
- Repository 测试：确认完成任务后会递减剩余次数，并在最后一次停止生成 successor。
- UI/source 测试：确认 `Today` 页面会显示重复次数信息。
