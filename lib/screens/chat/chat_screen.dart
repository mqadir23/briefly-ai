import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class ChatScreen extends StatefulWidget {
	const ChatScreen({super.key});

	@override
	State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
	final TextEditingController _controller = TextEditingController();
	final List<String> _messages = <String>[];

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	void _send() {
		final String text = _controller.text.trim();
		if (text.isEmpty) return;
		setState(() {
			_messages.add(text);
			_controller.clear();
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.bgDark,
			appBar: AppBar(title: const Text('Chat')),
			body: Column(
				children: <Widget>[
					Expanded(
						child: _messages.isEmpty
								? const Center(
										child: Text(
											'Ask Briefly AI anything about the news.',
											style: TextStyle(color: AppColors.textSecondary),
										),
									)
								: ListView.builder(
										padding: const EdgeInsets.all(12),
										itemCount: _messages.length,
										itemBuilder: (BuildContext context, int index) {
											return Align(
												alignment: Alignment.centerRight,
												child: Container(
													margin: const EdgeInsets.only(bottom: 8),
													padding: const EdgeInsets.symmetric(
														horizontal: 12,
														vertical: 10,
													),
													decoration: BoxDecoration(
														color: AppColors.primaryBlue.withOpacity(0.2),
														borderRadius: BorderRadius.circular(12),
														border: Border.all(color: AppColors.dividerColor),
													),
													child: Text(
														_messages[index],
														style: const TextStyle(color: AppColors.textPrimary),
													),
												),
											);
										},
									),
					),
					SafeArea(
						top: false,
						child: Padding(
							padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
							child: Row(
								children: <Widget>[
									Expanded(
										child: TextField(
											controller: _controller,
											onSubmitted: (_) => _send(),
											style: const TextStyle(color: AppColors.textPrimary),
											decoration: InputDecoration(
												hintText: 'Type a message',
												hintStyle:
														const TextStyle(color: AppColors.textHint),
												filled: true,
												fillColor: AppColors.bgCard,
												border: OutlineInputBorder(
													borderRadius: BorderRadius.circular(12),
													borderSide:
															const BorderSide(color: AppColors.dividerColor),
												),
												enabledBorder: OutlineInputBorder(
													borderRadius: BorderRadius.circular(12),
													borderSide:
															const BorderSide(color: AppColors.dividerColor),
												),
												focusedBorder: OutlineInputBorder(
													borderRadius: BorderRadius.circular(12),
													borderSide:
															const BorderSide(color: AppColors.primaryBlue),
												),
											),
										),
									),
									const SizedBox(width: 8),
									FilledButton(
										onPressed: _send,
										child: const Icon(Icons.send_rounded),
									),
								],
							),
						),
					),
				],
			),
		);
	}
}
