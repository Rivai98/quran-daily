import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/reader_cubit.dart';

/// Retains visited page state only inside the reader's two-page neighborhood.
class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.pageNumber, required this.child});

  final int pageNumber;
  final Widget child;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>
    with AutomaticKeepAliveClientMixin {
  bool _nearby(ReaderState state) =>
      ((state.page?.number ?? widget.pageNumber) - widget.pageNumber).abs() <=
      2;

  @override
  bool get wantKeepAlive => _nearby(context.read<ReaderCubit>().state);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<ReaderCubit, ReaderState>(
      listenWhen: (previous, current) => _nearby(previous) != _nearby(current),
      listener: (context, state) => updateKeepAlive(),
      child: widget.child,
    );
  }
}
