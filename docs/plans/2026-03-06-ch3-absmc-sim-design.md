# Chapter 3 ABSMC Simulation Slides Design

## Goal
将 `/Users/xiakaiyang/Projects/BSMC_Sim.py` 生成的第 3 章仿真图（Fig 5-1 至 Fig 5-6）嵌入 `/Users/xiakaiyang/Desktop/quadrotor_control_presentation.html` 的 ABSMC 实验仿真部分，并补充参考文献“哈尔滨理工大学硕士毕业论文《四旋翼飞行器的滑模控制算法研究》”。

## Chosen Approach
采用直接复用现有 `BSMC_Sim.py` 的方式生成图片，再按现有 HTML 演示稿的学术型版式拆分为多页连续仿真页。这样可以最大程度保持图号、图意、脚本来源与论文结构一致，同时避免在单页内堆叠过多内容导致 viewport 溢出。

## Layout Design
- 保留现有 `ch3-7` 作为“仿真场景与参数说明”页。
- 追加连续仿真结果页，分别承载：
  - 基础跟踪图（Fig 5-1, Fig 5-2）
  - 扰动响应图一（Fig 5-3, Fig 5-4）
  - 扰动响应图二（Fig 5-5, Fig 5-6）
- 每页使用紧凑学术布局：标题、双图网格、图注/结论框。
- 在仿真结果页底部加入参考文献信息。

## Implementation Notes
- 若 `BSMC_Sim.py` 当前仅 `plt.show()` 而不保存图片，则对其做最小改动，增加稳定输出 PNG 的逻辑，不改变仿真算法。
- HTML 中图片尺寸遵守 `frontend-slides` 的 viewport 规则，采用受限高度和对象适配，必要时拆页。
- 参考文献仅加入到第 3 章仿真部分，不改其他章节内容。

## Verification
- 先验证当前不存在目标图片或 HTML 未嵌入图像。
- 运行脚本并确认 6 张图片落盘。
- 打开 HTML，确认新仿真页显示正常且无溢出。
