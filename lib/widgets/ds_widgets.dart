import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/ds.dart';

/// Soft grey-white gradient behind every screen.
class DsBackground extends StatelessWidget {
  const DsBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: DS.backgroundGradient),
    child: SizedBox.expand(child: child),
  );
}

/// Round white back button.
class DsBackButton extends StatelessWidget {
  const DsBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Back'.tr,
    child: GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: DS.softShadow,
        ),
        child: const Icon(Icons.chevron_left_rounded, size: 28, color: DS.ink),
      ),
    ),
  );
}

/// Two-line title: light first line, bold second line.
class DsTitle extends StatelessWidget {
  const DsTitle(this.first, this.second, {super.key, this.size = 40});
  final String first;
  final String second;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Translated as a pair ("Your|trends"), since word order differs between
    // languages. An empty first part means the title fits on one line.
    final parts = '$first|$second'.tr.split('|');
    final (a, b) = parts.length == 2 ? (parts[0], parts[1]) : (first, second);
    return Text.rich(
      TextSpan(
        children: [
          if (a.isNotEmpty)
            TextSpan(
              text: '$a\n',
              style: DS.text(size: size, weight: FontWeight.w500),
            ),
          TextSpan(
            text: b,
            style: DS.text(size: size, weight: FontWeight.w800),
          ),
        ],
      ),
      style: TextStyle(
        height: 1.1,
        letterSpacing: L10n.current == AppLanguage.ar ? 0 : -size * 0.02,
      ),
    );
  }
}

class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.color = DS.card,
    this.shadow = true,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? DS.cardShadow() : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

class DsPrimaryButton extends StatelessWidget {
  const DsPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color = DS.navy,
    this.height = 62,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1,
          child: Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DS.text(
                            size: height < 60 ? 16 : 18,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class DsOutlineButton extends StatelessWidget {
  const DsOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = DS.ink,
    this.iconColor = DS.navy,
    this.height = 58,
    this.fill = Colors.white,
    this.fontSize = 16,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color iconColor;
  final double height;
  final Color fill;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DS.hairline, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DS.text(
                  size: fontSize,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Quiet text-only action ("Retake photo", "Forgot password?").
class DsTextAction extends StatelessWidget {
  const DsTextAction(
    this.label, {
    super.key,
    required this.onPressed,
    this.color = DS.navy,
    this.alignment = Alignment.center,
  });
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onPressed,
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: alignment,
      child: Text(
        label,
        style: DS.text(size: 15.5, weight: FontWeight.w700, color: color),
      ),
    ),
  );
}

class DsPill extends StatelessWidget {
  const DsPill(
    this.label, {
    super.key,
    required this.background,
    required this.foreground,
    this.dot,
    this.size = 13,
    this.vertical = 7,
  });
  final String label;
  final Color background;
  final Color foreground;
  final Color? dot;
  final double size;
  final double vertical;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 13, vertical: vertical),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: DS.text(
              size: size,
              weight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ],
    ),
  );
}

class DsSectionHeader extends StatelessWidget {
  const DsSectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DS.text(size: 17, weight: FontWeight.w700),
        ),
      ),
      if (action != null)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAction,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.centerRight,
            child: Text(
              action!,
              style: DS.text(
                size: 14,
                weight: FontWeight.w600,
                color: DS.muted,
              ),
            ),
          ),
        ),
    ],
  );
}

/// Round icon with a label under it (Quick actions).
class DsQuickAction extends StatelessWidget {
  const DsQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = DS.navy,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DS.navy.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 27, color: iconColor),
            ),
            const SizedBox(height: 9),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: DS.text(size: 13.5, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// White rounded text field with an icon, used on sign in / create account.
class DsTextField extends StatelessWidget {
  const DsTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.trailing,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? trailing;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: DS.softShadow,
    ),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: DS.text(size: 16.5, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: DS.text(
          size: 16.5,
          weight: FontWeight.w500,
          color: DS.iconMuted,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 21),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 20, right: 14),
          child: Icon(icon, size: 22, color: DS.navy),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: trailing,
        errorStyle: DS.text(size: 12.5, color: DS.redText),
      ),
    ),
  );
}

/// Grey input pill used inside cards (value fields, date field).
InputDecoration dsFieldDecoration({
  String? hint,
  Widget? prefix,
  Widget? suffix,
  double vertical = 18,
}) => InputDecoration(
  hintText: hint,
  hintStyle: DS.text(size: 17, weight: FontWeight.w600, color: DS.iconMuted),
  filled: true,
  fillColor: DS.field,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: DS.navy, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: DS.red, width: 1.5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: DS.red, width: 1.5),
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: vertical),
  prefixIcon: prefix,
  suffixIcon: suffix,
  errorStyle: DS.text(size: 12.5, color: DS.redText),
);

/// Small segmented control (units, sex, language).
class DsSegmented<T> extends StatelessWidget {
  const DsSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 44,
    this.fontSize = 13.5,
    this.background = DS.field,
    this.radius = 18,
  });
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final double fontSize;
  final Color background;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Row(
      children: [
        for (final entry in options.entries)
          Expanded(
            child: Semantics(
              button: true,
              selected: entry.key == value,
              label: entry.value,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(entry.key),
                child: Container(
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.key == value ? DS.navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(radius - 4),
                  ),
                  child: Text(
                    entry.value,
                    style: DS.text(
                      size: fontSize,
                      weight: entry.key == value
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: entry.key == value ? Colors.white : DS.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// On/off switch drawn like the design (navy track, white knob).
class DsSwitch extends StatelessWidget {
  const DsSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    child: GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 54,
        height: 32,
        padding: const EdgeInsets.all(4),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? DS.navy : DS.hairline,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

/// Round icon badge used in rows (settings, medicine, quick info).
class DsIconBadge extends StatelessWidget {
  const DsIconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.background = DS.skyTint,
    this.color = DS.navy,
  });
  final IconData icon;
  final double size;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, size: size * 0.5, color: color),
  );
}

/// Round photo of a (placeholder) doctor.
class DsDoctorAvatar extends StatelessWidget {
  const DsDoctorAvatar({super.key, required this.asset, this.size = 56});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.6),
      excludeFromSemantics: true,
    ),
  );
}
