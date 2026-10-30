import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/attendance_model.dart';

class SummaryByEmployeeTable extends StatelessWidget {
  final AttendanceSummaryResponse data;
  final Function(int userId)? onEmployeeClick;

  const SummaryByEmployeeTable({
    super.key,
    required this.data,
    this.onEmployeeClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.employees.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Không có dữ liệu nhân viên phù hợp với tìm kiếm'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              ),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columnSpacing: 24,
              horizontalMargin: 16,
              columns: const [
                DataColumn(
                  label: Text('Nhân viên', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Đi làm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Nghỉ làm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Đi muộn', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Về sớm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Tăng ca', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: data.employees.map((emp) {
                if (emp.noData) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text('${emp.fullName} (${emp.staffCode})',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const DataCell(Text('-', style: TextStyle(color: Colors.grey))),
                      const DataCell(Text('-', style: TextStyle(color: Colors.grey))),
                      const DataCell(Text('-', style: TextStyle(color: Colors.grey))),
                      const DataCell(Text('-', style: TextStyle(color: Colors.grey))),
                      const DataCell(Text('-', style: TextStyle(color: Colors.grey))),
                      DataCell(
                        TextButton(
                          onPressed: onEmployeeClick != null ? () => onEmployeeClick!(emp.userId) : null,
                          child: const Text('Chấm công'),
                        ),
                      ),
                    ],
                  );
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(emp.staffCode,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${emp.workShiftCount} ca',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(emp.workHoursTotal, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    DataCell(
                      emp.leaveShiftCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${emp.leaveShiftCount} ca',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
                    DataCell(
                      emp.lateCount > 0
                          ? Text(
                              '${emp.lateCount} lần (${emp.lateDuration})',
                              style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w600, fontSize: 12),
                            )
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
                    DataCell(
                      emp.earlyLeaveCount > 0
                          ? Text(
                              '${emp.earlyLeaveCount} lần (${emp.earlyLeaveDuration})',
                              style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w600, fontSize: 12),
                            )
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
                    DataCell(
                      emp.overtime != '0m'
                          ? Text(emp.overtime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
                    DataCell(
                      ElevatedButton(
                        onPressed: onEmployeeClick != null ? () => onEmployeeClick!(emp.userId) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Chấm công', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

