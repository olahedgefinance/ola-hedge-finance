import 'package:budget/brand/ola_theme.dart';
import 'package:budget/widgets/ola/ola_focus_outline.dart';
import 'package:flutter/material.dart';

/// Presentation only: financial streams and route ownership stay in Home.
class OlaDashboardScope extends InheritedWidget {
  const OlaDashboardScope({super.key, required super.child, this.hero = false});
  final bool hero;
  static OlaDashboardScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OlaDashboardScope>();
  static bool active(BuildContext context) => of(context) != null;
  @override
  bool updateShouldNotify(OlaDashboardScope oldWidget) =>
      hero != oldWidget.hero;
}

enum OlaMetricStatus { neutral, positive, negative, attention }

class OlaMetricCard extends StatelessWidget {
  const OlaMetricCard(
      {super.key,
      required this.label,
      required this.value,
      required this.contextLabel,
      this.status = OlaMetricStatus.neutral,
      this.isLoading = false,
      this.errorText,
      this.onTap,
      this.onLongPress,
      this.hero = false});
  final String label, value, contextLabel;
  final OlaMetricStatus status;
  final bool isLoading, hero;
  final String? errorText;
  final VoidCallback? onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color statusColor = switch (status) {
      OlaMetricStatus.positive => colors.primary,
      OlaMetricStatus.negative => colors.error,
      OlaMetricStatus.attention => colors.tertiary,
      OlaMetricStatus.neutral => colors.onSurfaceVariant,
    };
    final radius = BorderRadius.circular(hero ? OlaRadii.xl : OlaRadii.lg);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: radius, side: BorderSide(color: colors.outlineVariant)),
      child: OlaFocusOutline(
          radius: radius,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsets.all(hero ? OlaSpacing.lg : OlaSpacing.md),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 14, color: colors.onSurfaceVariant)),
                    const SizedBox(height: OlaSpacing.sm),
                    if (errorText != null)
                      Text(errorText!,
                          style: TextStyle(fontSize: 16, color: colors.error))
                    else if (isLoading)
                      Semantics(liveRegion: true, child: const Text('Loading…'))
                    else ...[
                      Text(value,
                          softWrap: true,
                          style: TextStyle(
                              fontSize: hero ? 32 : 26,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface)),
                      const SizedBox(height: OlaSpacing.sm),
                      Text(contextLabel,
                          style: TextStyle(fontSize: 14, color: statusColor)),
                    ],
                  ]),
            ),
          )),
    );
  }
}

/// Retains the existing Row outside Home; large text stacks the same cards.
class OlaMetricPair extends StatelessWidget {
  const OlaMetricPair(
      {super.key,
      required this.children,
      this.crossAxisAlignment = CrossAxisAlignment.center,
      this.mainAxisAlignment = MainAxisAlignment.start});
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  @override
  Widget build(BuildContext context) {
    if (!OlaDashboardScope.active(context)) {
      return Row(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          children: children);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      if (constraints.maxWidth >= 300 && scale <= 1.3) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start, children: children);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final child in children)
          if (child is Expanded)
            child.child
          else if (child is SizedBox)
            const SizedBox(height: OlaSpacing.md)
          else
            child,
      ]);
    });
  }
}

class OlaDashboardHeader extends StatelessWidget {
  const OlaDashboardHeader(
      {super.key, required this.onCustomize, this.greeting});
  final VoidCallback onCustomize;
  final String? greeting;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 24, 13, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text('INTERNAL DEVELOPMENT',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant))),
          IconButton(
              tooltip: 'Customize dashboard',
              onPressed: onCustomize,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.tune_rounded)),
        ]),
        if (greeting != null && greeting!.isNotEmpty) ...[
          Text(greeting!,
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant)),
          const SizedBox(height: OlaSpacing.xs),
        ],
        Semantics(
            header: true,
            child: Text('Your financial health',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface))),
        const SizedBox(height: OlaSpacing.sm),
        Text('A clear view of your recorded finances.',
            style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant)),
        const SizedBox(height: OlaSpacing.md),
        Text('Wealth under protection',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.primary)),
      ]),
    );
  }
}

class OlaDashboardSection extends StatelessWidget {
  const OlaDashboardSection(
      {super.key,
      required this.title,
      required this.child,
      this.scopeLabel,
      this.onViewAll});
  final String title;
  final String? scopeLabel;
  final Widget child;
  final VoidCallback? onViewAll;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: OlaSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(13, 0, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Semantics(
                          header: true,
                          child: Text(title,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface)))),
                  if (onViewAll != null)
                    IconButton(
                        tooltip: 'View all $title',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: onViewAll,
                        icon: const Icon(Icons.arrow_forward_rounded)),
                ]),
                if (scopeLabel != null) ...[
                  const SizedBox(height: OlaSpacing.xs),
                  Text(scopeLabel!,
                      style: TextStyle(
                          fontSize: 14, color: colors.onSurfaceVariant)),
                ],
              ],
            )),
        child,
      ]),
    );
  }
}

class OlaDashboardBody extends StatelessWidget {
  const OlaDashboardBody(
      {super.key,
      required this.header,
      required this.centerSections,
      this.leftSections = const [],
      this.rightSections = const []});
  final Widget header;
  final List<Widget> centerSections, leftSections, rightSections;
  @override
  Widget build(BuildContext context) => OlaDashboardScope(child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          // Legacy Home modules own 13 px insets; together these yield 24/48 px.
          final inset = (wide ? OlaSpacing.xxl : OlaSpacing.lg) - 13;
          return Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    ...centerSections,
                    if (wide &&
                        leftSections.isNotEmpty &&
                        rightSections.isNotEmpty)
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: leftSections)),
                            const SizedBox(width: OlaSpacing.lg),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: rightSections)),
                          ])
                    else ...[...leftSections, ...rightSections],
                    const SizedBox(height: OlaSpacing.xxxl),
                  ]),
            ),
          ));
        },
      ));
}

class OlaDataState extends StatelessWidget {
  const OlaDataState({super.key, this.error = false, this.message});
  final bool error;
  final String? message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(OlaSpacing.md),
        child: Text(
            message ?? (error ? 'Unable to load. Try refreshing.' : 'Loading…'),
            style: TextStyle(
                fontSize: 16,
                color: error
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}
