import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation/route_next.dart';

/// A single item in the [RouteNextCommandPalette].
///
/// Items can either navigate to a [path] or invoke an arbitrary [onSelect]
/// callback — useful for non-navigation actions like toggling settings.
@immutable
class CommandItem {
  /// Creates a [CommandItem].
  ///
  /// Either [path] or [onSelect] must be provided.
  const CommandItem({
    required this.label,
    this.description,
    this.icon,
    this.path,
    this.onSelect,
    this.group,
  }) : assert(path != null || onSelect != null,
            'CommandItem requires either a path or an onSelect callback.');

  /// Primary display label.
  final String label;

  /// Optional secondary description shown below the label.
  final String? description;

  /// Optional leading icon.
  final IconData? icon;

  /// Route path to navigate to when selected.
  ///
  /// If set, [RouteNext.push] is called with this path on selection.
  final String? path;

  /// Arbitrary callback invoked when the item is selected.
  ///
  /// Takes precedence over [path] when both are provided.
  final VoidCallback? onSelect;

  /// Optional group name used to visually section results.
  final String? group;
}

/// A Cmd+K / Ctrl+K command palette overlay for quick navigation and actions.
///
/// Wrap your app shell or any ancestor widget with [RouteNextCommandPalette].
/// The palette opens when the user presses ⌘K (macOS) or Ctrl+K (other
/// platforms) and dismisses on Escape or an outside tap.
///
/// Supports fuzzy-style filtering (substring, case-insensitive) across
/// [label] and [description] fields.
///
/// Example:
/// ```dart
/// RouteNextCommandPalette(
///   commands: [
///     CommandItem(label: 'Dashboard', icon: Icons.dashboard, path: '/dashboard'),
///     CommandItem(label: 'Settings',  icon: Icons.settings,  path: '/settings'),
///     CommandItem(
///       label: 'Toggle dark mode',
///       icon: Icons.dark_mode,
///       group: 'Actions',
///       onSelect: () => themeNotifier.toggle(),
///     ),
///   ],
///   child: MyAppShell(),
/// )
/// ```
class RouteNextCommandPalette extends StatefulWidget {
  /// Creates a [RouteNextCommandPalette].
  const RouteNextCommandPalette({
    super.key,
    required this.commands,
    required this.child,
    this.placeholder = 'Search commands…',
    this.maxHeight = 420.0,
    this.width = 560.0,
  });

  /// Full list of available commands.
  final List<CommandItem> commands;

  /// The widget subtree that registers the keyboard shortcut.
  final Widget child;

  /// Placeholder text shown in the search field.
  final String placeholder;

  /// Maximum height of the results list. Defaults to `420`.
  final double maxHeight;

  /// Width of the palette overlay. Defaults to `560`.
  final double width;

  @override
  State<RouteNextCommandPalette> createState() =>
      _RouteNextCommandPaletteState();
}

class _RouteNextCommandPaletteState extends State<RouteNextCommandPalette> {
  OverlayEntry? _overlay;
  final _searchController = TextEditingController();
  final _keyListenerFocus = FocusNode();

  @override
  void dispose() {
    _dismiss();
    _searchController.dispose();
    _keyListenerFocus.dispose();
    super.dispose();
  }

  void _open() {
    if (_overlay != null) return;
    _searchController.clear();
    _overlay = OverlayEntry(
      builder: (_) => _PaletteOverlay(
        commands: widget.commands,
        searchController: _searchController,
        placeholder: widget.placeholder,
        maxHeight: widget.maxHeight,
        width: widget.width,
        onDismiss: _dismiss,
        onSelect: _handleSelect,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _dismiss() {
    _overlay?.remove();
    _overlay = null;
  }

  void _handleSelect(CommandItem item) {
    _dismiss();
    if (item.onSelect != null) {
      item.onSelect!();
    } else if (item.path != null) {
      RouteNext.of(context).push(item.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyListenerFocus,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final isCtrlOrCmd = HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed;
        if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyK) {
          _overlay == null ? _open() : _dismiss();
        }
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Private overlay widget
// ---------------------------------------------------------------------------

class _PaletteOverlay extends StatefulWidget {
  const _PaletteOverlay({
    required this.commands,
    required this.searchController,
    required this.placeholder,
    required this.maxHeight,
    required this.width,
    required this.onDismiss,
    required this.onSelect,
  });

  final List<CommandItem> commands;
  final TextEditingController searchController;
  final String placeholder;
  final double maxHeight;
  final double width;
  final VoidCallback onDismiss;
  final void Function(CommandItem) onSelect;

  @override
  State<_PaletteOverlay> createState() => _PaletteOverlayState();
}

class _PaletteOverlayState extends State<_PaletteOverlay> {
  List<CommandItem> _filtered = [];
  int _selectedIndex = 0;
  final FocusNode _inputFocus = FocusNode();
  final FocusNode _keyListenerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _filtered = widget.commands;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocus.requestFocus();
    });
    widget.searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearch);
    _inputFocus.dispose();
    _keyListenerFocus.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = widget.searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.commands
          : widget.commands.where((c) {
              return c.label.toLowerCase().contains(q) ||
                  (c.description?.toLowerCase().contains(q) ?? false) ||
                  (c.group?.toLowerCase().contains(q) ?? false);
            }).toList();
      _selectedIndex = 0;
    });
  }

  void _moveSelection(int delta) {
    if (_filtered.isEmpty) return;
    setState(() {
      _selectedIndex =
          (_selectedIndex + delta).clamp(0, _filtered.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return KeyboardListener(
      focusNode: _keyListenerFocus,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _moveSelection(1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _moveSelection(-1);
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_filtered.isNotEmpty) {
            widget.onSelect(_filtered[_selectedIndex]);
          }
        }
      },
      child: Stack(
        children: [
          // Scrim — tap to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          // Palette panel
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.width,
                maxHeight: widget.maxHeight + 56,
              ),
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: widget.searchController,
                        focusNode: _inputFocus,
                        decoration: InputDecoration(
                          hintText: widget.placeholder,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                          filled: false,
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    // Results
                    if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No results',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: widget.maxHeight),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _CommandTile(
                            item: _filtered[i],
                            isSelected: i == _selectedIndex,
                            onTap: () => widget.onSelect(_filtered[i]),
                            onHover: (hovering) {
                              if (hovering) setState(() => _selectedIndex = i);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  final CommandItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(bool hovering) onHover;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : null,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 18,
                    color: isSelected ? colorScheme.primary : null),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : null,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                  ],
                ),
              ),
              if (item.group != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.group!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
