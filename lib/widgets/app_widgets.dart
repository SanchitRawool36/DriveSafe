import 'package:flutter/material.dart';

class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle ?? '',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ],
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final button = icon == null
            ? ElevatedButton(onPressed: onPressed, child: Text(label))
            : ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));

        if (constraints.hasBoundedWidth) {
          return SizedBox(width: constraints.maxWidth, child: button);
        }

        return button;
      },
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final button = icon == null
            ? OutlinedButton(onPressed: onPressed, child: Text(label))
            : OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label));

        if (constraints.hasBoundedWidth) {
          return SizedBox(width: constraints.maxWidth, child: button);
        }

        return button;
      },
    );
  }
}

class AppInfoCard extends StatelessWidget {
  final Widget child;

  const AppInfoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class ComplaintStatusChip extends StatelessWidget {
  final String status;

  const ComplaintStatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'Accepted':
      case 'Resolved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return const Color(0xFFF6B400);
      case 'In Progress':
        return Colors.orange;
      default:
        return const Color(0xFF0B65C2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
