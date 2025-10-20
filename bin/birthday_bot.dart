import 'dart:async';
import 'package:birthday_bot/bloc/birthday_bloc.dart';
import 'package:birthday_bot/data/services/birthday_api_service.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

void main() async {

  // admin_id:
  const List<int> adminIds = [5505290719, 7847026426];

  // bloc_setup:
  final bloc = BirthdayBloc(BirthdayApiService());
  final api = BirthdayApiService();

  bool isAdmin(int? userId) {
    return userId != null && adminIds.contains(userId);
  }

  // bot_token:
  const botToken = "8437865387:AAHjGFZWHkULFT2y6xQD1618_8UOgL6UXIA";

  // group_id:
  const groupId = -1002481910630;


  final telegram = Telegram(botToken);
  final me = await telegram.getMe();
  final userName = me.username;

  const bool testMode = false;


  // teledart_init:
  final teleDart = TeleDart(botToken, Event(userName!));
  teleDart.start();
  print("- Bot @$userName ishga tushdi!");

  await telegram.setMyCommands([
    BotCommand(command: 'start', description: 'Start Bot'),
  ]);

  // state:
  final Map<int, String> userStates = {};
  final Map<int, String> tempNames = {};

  // main_buttons:
  InlineKeyboardMarkup getMainMenu() {
    return InlineKeyboardMarkup(inlineKeyboard: [
      [
        InlineKeyboardButton(text: '➕ Yangi qo\'shish', callbackData: 'add_new'),
        InlineKeyboardButton(text: '📋 Ro\'yxat', callbackData: 'show_list'),
      ],
      [
        InlineKeyboardButton(text: '🗑 O\'chirish', callbackData: 'delete_menu'),
        InlineKeyboardButton(text: '📊 Statistika', callbackData: 'stats'),
      ],
      [
        InlineKeyboardButton(text: '🔄 Yangilash', callbackData: 'refresh'),
        InlineKeyboardButton(text: 'ℹ️ Yordam', callbackData: 'help'),
      ],
    ]);
  }

  InlineKeyboardMarkup getCancelButton() {
    return InlineKeyboardMarkup(inlineKeyboard: [
      [InlineKeyboardButton(text: '❌ Bekor qilish', callbackData: 'cancel')]
    ]);
  }

  Future<void> sendMainMenu(dynamic message, {String? customText}) async {
    final text = customText ??
        '🎂 <b>Tug\'ilgan Kunlar Boshqaruvi</b>\n\n'
            '👋 Xush kelibsiz!\n'
            'Kerakli bo\'limni tanlang 👇';

    await telegram.sendMessage(
      message.chat.id,
      text,
      replyMarkup: getMainMenu(),
      parseMode: 'HTML',
    );
  }

  Future<void> editMenuMessage(
      CallbackQuery query, String text, InlineKeyboardMarkup keyboard) async {
    try {
      await telegram.editMessageText(
        text,
        chatId: query.message?.chat.id,
        messageId: query.message?.messageId,
        replyMarkup: keyboard,
        parseMode: 'HTML',
      );
    } catch (e) {
      print("⚠️ editMenuMessage error: $e");
    }
  }

  // /start
  teleDart.onCommand('start').listen((message) async {

    if (message.chat.type == "group" || message.chat.type == "supergroup") {
      await telegram.sendMessage(
        message.chat.id,
               'ℹ️ Bu buyruq faqat shaxsiy chatda ishlaydi.\n'
              'Iltimos, botga shaxsiy xabar yozing 👉 @x_birthday_reminder_bot',
      );
      return;
    }
    if (!isAdmin(message.from?.id)) {
      message.reply('⛔ Bu bot faqat admin uchun!');
      return;
    }

    await telegram.sendMessage(
      message.chat.id,
      '🎂 <b>Tug\'ilgan Kunlar Boshqaruvi</b>\n\n'
          '👋 Xush kelibsiz!\n'
          'Kerakli bo\'limni tanlang 👇',
      replyMarkup: ReplyKeyboardMarkup(
        keyboard: [
          [KeyboardButton(text: '🏠 Menyu')]
        ],
        resizeKeyboard: true,
        isPersistent: true,
      ),
      parseMode: 'HTML',
    );

    sendMainMenu(message);
  });

  // menu_button:
  teleDart.onMessage(keyword: '🏠 Menyu').listen((message) {
    if (!isAdmin(message.from?.id)) return;
    sendMainMenu(message);
  });

  // name_date_of_birth_field:
  teleDart.onMessage(keyword: null).listen((message) async {
    final userId = message.from?.id;
    if (userId == null || !isAdmin(message.from?.id)) return;

    final state = userStates[userId];
    final text = message.text;

    if (state == 'waiting_name' && text != null && !text.startsWith('/')) {
      tempNames[userId] = text;
      userStates[userId] = 'waiting_date';

      message.reply(
        '📅 <b>Endi tug\'ilgan kunni kiriting:</b>\n\n'
            'Format: <code>DD-MM-YYYY</code>\n'
            'Masalan: <code>01-08-2006</code>',
        replyMarkup: getCancelButton(),
        parseMode: 'HTML',
      );
    } else if (state == 'waiting_date' && text != null && !text.startsWith('/')) {
      final dateRegex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
      if (!dateRegex.hasMatch(text)) {
        message.reply(
          '❗ Noto\'g\'ri format!\nTo\'g\'ri format: DD-MM-YYYY',
          replyMarkup: getCancelButton(),
        );
        return;
      }

      final name = tempNames[userId]!;
      final parts = text.split('-');
      final formattedDate = '${parts[2]}-${parts[1]}-${parts[0]}';

      bloc.add(AddBirthday(name, formattedDate));
      userStates.remove(userId);
      tempNames.remove(userId);

      await message.reply(
        '✅ <b>Qo\'shildi!</b>\n👤 Ism: $name\n📅 Sana: $text',
        parseMode: 'HTML',
      );

      sendMainMenu(message, customText: '✅ Ma\'lumot bazaga saqlandi!');
    }
  });

  // callback_handler_buttons:
  teleDart.onCallbackQuery().listen((query) async {
    if (!isAdmin(query.from.id)) {
      await query.answer(text: '⛔ Ruxsat yo‘q!', showAlert: true);
      return;
    }

    final data = query.data;

    if (data == 'add_new') {
      userStates[query.from.id] = 'waiting_name';
      await editMenuMessage(
        query,
        '➕ <b>Yangi tug\'ilgan kun qo\'shish</b>\n\n'
            '👤 Ism kiriting:',
        getCancelButton(),
      );
    }

    // list_of_people:
    else if (data == 'show_list') {
      bloc.add(LoadBirthdays());
      await Future.delayed(const Duration(seconds: 1));
      final state = bloc.state;

      if (state.birthdays.isEmpty) {
        await editMenuMessage(
          query,
          '📭 <b>Ro‘yxat bo‘sh</b>',
          getMainMenu(),
        );
      } else {
        final list = state.birthdays
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. 🎂 <b>${e.value.name}</b> — <code>${e.value.date}</code>')
            .join('\n');

        await editMenuMessage(
          query,
          '📋 <b>Tug‘ilgan Kunlar Ro‘yxati</b>\n\n$list',
          InlineKeyboardMarkup(inlineKeyboard: [
            [InlineKeyboardButton(text: '🔙 Orqaga', callbackData: 'back_main')]
          ]),
        );
      }
      await query.answer();
    }

    // statistic:
    else if (data == 'stats') {
      final stats = await api.getStats();
      await editMenuMessage(
        query,
        '📊 <b>Statistika</b>\n\n'
            '👥 Jami: <b>${stats["total"]}</b> ta\n'
            '🎂 Shu oyda: <b>${stats["this_month"]}</b> ta',
        InlineKeyboardMarkup(inlineKeyboard: [
          [InlineKeyboardButton(text: '🔙 Orqaga', callbackData: 'back_main')]
        ]),
      );
      await query.answer();
    }

    // delete_menu:
    else if (data == 'delete_menu') {
      bloc.add(LoadBirthdays());
      await Future.delayed(const Duration(seconds: 1));
      final state = bloc.state;

      if (state.birthdays.isEmpty) {
        await query.answer(text: '📭 Ro‘yxat bo‘sh!', showAlert: true);
      } else {
        final buttons = state.birthdays.asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          return [
            InlineKeyboardButton(
              text: '❌ ${b.name} (${b.date})',
              callbackData: 'delete_${b.id}',
            )
          ];
        }).toList();

        buttons.add([
          InlineKeyboardButton(text: '🔙 Orqaga', callbackData: 'back_main')
        ]);

        await editMenuMessage(
          query,
          '🗑 <b>O‘chirish</b>\n\nQaysi ma’lumotni o‘chirmoqchisiz?',
          InlineKeyboardMarkup(inlineKeyboard: buttons),
        );
      }
      await query.answer();
    }

    // delete_action:
    else if (data?.startsWith('delete_') ?? false) {
      final id = int.tryParse(data!.split('_')[1]);
      if (id != null) {
        bloc.add(DeleteBirthday(id));
        await query.answer(text: '✅ O‘chirildi!', showAlert: true);

        // refresh:
        bloc.add(LoadBirthdays());
        await Future.delayed(const Duration(milliseconds: 800));
        final state = bloc.state;

        if (state.birthdays.isEmpty) {
          await editMenuMessage(
            query,
            '✅ <b>O‘chirildi!</b>\n\n📭 Ro‘yxat endi bo‘sh.',
            getMainMenu(),
          );
        } else {
          final buttons = state.birthdays.asMap().entries.map((entry) {
            final b = entry.value;
            return [
              InlineKeyboardButton(
                text: '❌ ${b.name} (${b.date})',
                callbackData: 'delete_${b.id}',
              )
            ];
          }).toList();
          buttons.add([
            InlineKeyboardButton(text: '🔙 Orqaga', callbackData: 'back_main')
          ]);

          await editMenuMessage(
            query,
            '✅ <b>O‘chirildi!</b>\n\nYana o‘chirmoqchimisiz?',
            InlineKeyboardMarkup(inlineKeyboard: buttons),
          );
        }
      }
    }

    // help:
    else if (data == 'help') {
      await editMenuMessage(
        query,
        'ℹ️ <b>Qo‘llanma</b>\n\n'
            '➕ <b>Yangi qo‘shish</b> — yangi tug‘ilgan kun qo‘shish\n'
            '📋 <b>Ro‘yxat</b> — barcha ma’lumotlarni ko‘rish\n'
            '🗑 <b>O‘chirish</b> — ma’lumotni o‘chirish\n'
            '📊 <b>Statistika</b> — umumiy ma’lumotlar\n\n'
            '🤖 Bot har kuni avtomatik ravishda guruhga eslatma yuboradi!'
            '👤 <b>Creator</b> — @xurshidbek_006 takliflar bo\'lsa',
          InlineKeyboardMarkup(inlineKeyboard: [
          [InlineKeyboardButton(text: '🔙 Orqaga', callbackData: 'back_main')]
        ]),
      );
      await query.answer();
    }

    // refresh:
    else if (data == 'refresh') {
      await editMenuMessage(
        query,
        '🎂 <b>Tug‘ilgan Kunlar Boshqaruvi</b>\n\n'
            '👋 Xush kelibsiz!\n'
            'Kerakli bo‘limni tanlang 👇',
        getMainMenu(),
      );
      await query.answer(text: '🔄 Yangilandi!');
    }

    // back:
    else if (data == 'back_main' || data == 'cancel') {
      userStates.remove(query.from.id);
      tempNames.remove(query.from.id);
      await editMenuMessage(
        query,
        '🏠 Bosh menyu',
        getMainMenu(),
      );
      await query.answer();
    }
  });


  // checking_every_day_at_01:00:
  Timer.periodic(
    testMode ? const Duration(seconds: 30) : const Duration(minutes: 1),
        (_) async {
      try {
        final nowUtc = DateTime.now().toUtc();
        final tashkentTime = nowUtc.add(const Duration(hours: 5));

        if (testMode) {

          print("⏱ Test rejimi: ${tashkentTime.toIso8601String()} da tekshirildi.");

          final todayList = await api.getToday();

          if (todayList.isNotEmpty) {
            for (final b in todayList) {
              await telegram.sendMessage(
                groupId,
                '🎂 <b>${b.name}</b>ga bugungi kunda eng ezgu tilaklar! 💫\n\n'
                    '✨ Hayotingizda yangi yutuqlar, quvonch va muvaffaqiyatlar tilaymiz!\n'
                    '🎉 Tug‘ilgan kun muborak bo‘lsin! 🎉\n'
                    '😡 Tez hamma tabriklasin! Hattoki siz ham 😡',
                parseMode: 'HTML',
              );
            }
          } else {
            print("📭 Test rejimi: bugun tug‘ilgan kun yo‘q");
          }
        } else {
          final isOneAM = tashkentTime.hour == 1 && tashkentTime.minute == 0;

          if (isOneAM) {
            print("🕐 Tashkent time: ${tashkentTime.toIso8601String()} — sending birthday messages...");

            final todayList = await api.getToday();

            if (todayList.isNotEmpty) {
              for (final b in todayList) {
                await telegram.sendMessage(
                  groupId,
                  '🎂 <b>${b.name}</b>ga bugungi kunda eng ezgu tilaklar! 💫\n\n'
                      '✨ Hayotingizda yangi yutuqlar, quvonch va muvaffaqiyatlar tilaymiz!\n'
                      '🎉 Tug‘ilgan kun muborak bo‘lsin! 🎉\n'

                      '😡 Tez hamma tabriklasin! Hattoki siz ham 😡',
                  parseMode: 'HTML',
                );
              }
            } else {
              print("📭 Bugun tug‘ilgan kun yo‘q (Tashkent time: ${tashkentTime.toIso8601String()})");
            }

            await Future.delayed(const Duration(minutes: 1));
          }
        }
      } catch (e) {
        print("⚠️ Timer error: $e");
      }
    },
  );



}