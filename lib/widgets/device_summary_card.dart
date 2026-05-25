import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/device_offer.dart';
import '../models/phone_preset.dart';
import '../models/purchase_result.dart';
import '../theme/app_theme.dart';

// 기기 오퍼 목록에서 보여주는 요약 카드 위젯
class OfferSummaryCard extends StatelessWidget {
  final DeviceOffer offer;
  final PhonePreset phonePreset;
  final DeviceComparison comparison;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const OfferSummaryCard({
    super.key,
    required this.offer,
    required this.phonePreset,
    required this.comparison,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'ko_KR');
    final cheapestResult = comparison.cheapestResult;
    final methods = PurchaseMethod.values;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기종명 (크게)
              Text(
                phonePreset.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // 매장명 (부제)
              Text(
                offer.storeName,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.diffColor,
                ),
              ),
              const SizedBox(height: 8),
              // 최저 방식 + 금액
              Row(
                children: [
                  const Text('🏆 ', style: TextStyle(fontSize: 16)),
                  Text(
                    comparison.cheapest.label,
                    style: const TextStyle(
                      color: AppTheme.cheapest,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${fmt.format(cheapestResult.total)}원',
                    style: const TextStyle(
                      color: AppTheme.cheapest,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 나머지 방식 차액
              ...methods
                  .where((m) => m != comparison.cheapest)
                  .map((m) {
                final diff = comparison.diffFrom(m);
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${m.label}: +${fmt.format(diff)}원',
                    style: const TextStyle(
                      color: AppTheme.diffColor,
                      fontSize: 13,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
