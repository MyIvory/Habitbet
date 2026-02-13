# HabitBet - User Guide

## What is HabitBet?

HabitBet is a habit-building app where you put real stakes on your goals. Create a challenge, invite a friend as an arbiter, and prove daily that you're sticking to your habit. Complete the challenge — keep your money. Fail — and it goes to charity.

---

## Getting Started

### 1. Sign In

Open the app and tap **"Continue with Google"** (or **"Continue with Apple"** on iOS). This creates your account automatically.

### 2. Home Screen

After signing in you'll see the home screen with three tabs:

| Tab | Description |
|-----|-------------|
| **My Challenges** | Challenges you created |
| **Arbitrate** | Challenges where you are the arbiter (judge) |
| **Profile** | Your stats, settings, and sign out |

---

## Creating a Challenge

1. Tap the **"+"** button on the home screen
2. Fill in the challenge details:

| Field | Description | Example |
|-------|-------------|---------|
| **Title** | Short name for your challenge | "Morning Run 5km" |
| **Description** | What exactly counts as completing the task | "Run at least 5km before 9 AM, screenshot from running app as proof" |
| **Duration** | How many days the challenge lasts (7-90) | 21 days |
| **Days per week** | How many days per week you must complete the task | 5 days/week |
| **Stake amount** | Money you put on the line ($5 - $500) | $25 |
| **Charity** | Where the money goes if you fail | Red Cross, UNICEF, WWF, or Doctors Without Borders |
| **Arbiter name** | Name of the friend who will judge your proofs | "John" |
| **Arbiter email** | Their email (they need a HabitBet account) | "john@email.com" |

3. Tap **"Create Challenge"**
4. The challenge starts the next day

---

## Daily Routine

### Submitting Proof

Every day during your challenge:

1. Go to **My Challenges** and tap your active challenge
2. Find today's date in the calendar
3. Tap **"Submit Proof"**
4. Take a photo or choose from gallery — this is your evidence
5. Add an optional note explaining what you did
6. Tap **"Submit"**

Your proof will be sent to your arbiter for review.

### Deadlines

- You must submit proof before **23:59** on the day of the task
- If you miss the deadline, the day is marked as **missed**
- You'll receive a reminder notification at **20:00** if you haven't submitted yet

---

## Proof Statuses

Each day in your challenge has one of these statuses:

| Status | Icon | Meaning |
|--------|------|---------|
| **Pending** | Gray circle | No proof submitted yet, still time |
| **Submitted** | Yellow circle | Proof sent, waiting for arbiter review |
| **Approved** | Green checkmark | Arbiter confirmed your proof |
| **Rejected** | Red X | Arbiter rejected your proof (with reason) |
| **Missed** | Red circle | Deadline passed without proof |

---

## Being an Arbiter

If a friend invites you as an arbiter:

1. Go to the **Arbitrate** tab
2. You'll see challenges waiting for your review
3. Tap a challenge to see submitted proofs
4. For each proof you can:
   - **Approve** — the proof is valid, the day counts as completed
   - **Reject** — the proof is insufficient (you must provide a reason)

### Arbiter Guidelines

- Be fair and consistent
- Review proofs promptly (your friend is counting on you)
- Only approve proofs that genuinely meet the challenge criteria
- If rejecting, explain why so your friend knows what to improve

---

## Challenge Outcomes

### Challenge Completed

If you meet the required number of days:
- The challenge is marked as **completed**
- Your stake is returned (no money charged)
- Your profile stats update

### Challenge Failed

If you don't meet the required number of days:
- The challenge is marked as **failed**
- Your stake goes to the selected charity
- Your profile stats update

### How Days Are Counted

The app calculates whether you succeeded based on:
- **Duration**: total days of the challenge
- **Required days per week**: how many days per week you committed to
- **Total required days** = (duration / 7) x required days per week (rounded up)
- If your **approved days >= total required days**, you succeed

**Example**: 21-day challenge, 5 days/week = need at least 15 approved days.

---

## Profile & Statistics

Your profile shows:

| Stat | Description |
|------|-------------|
| **Created** | Total challenges you've created |
| **Completed** | Challenges you've successfully finished |
| **Failed** | Challenges you didn't complete |
| **Total Staked** | Total money you've put on the line |
| **Lost to Charity** | Total money that went to charity from failed challenges |

---

## Notifications

HabitBet sends push notifications for:

- **Daily reminder** (20:00) — if you haven't submitted today's proof
- **Proof submitted** — arbiter gets notified when you submit proof
- **Challenge updates** — status changes on your challenges

Make sure notifications are enabled in your phone settings for HabitBet.

---

## Tips for Success

1. **Start small** — pick a 7-day challenge first to test the flow
2. **Choose a reliable arbiter** — someone who will review proofs daily
3. **Set a daily routine** — do the task and submit proof at the same time each day
4. **Use the reminder** — don't ignore the 20:00 notification
5. **Be specific** — write a clear description so your arbiter knows exactly what to approve
6. **Take good photos** — make it obvious you completed the task

---

## Supported Charities

| Charity | Description |
|---------|-------------|
| **Red Cross** | Humanitarian aid worldwide |
| **UNICEF** | Children's welfare and education |
| **WWF** | Wildlife and environmental conservation |
| **Doctors Without Borders** | Medical aid in crisis zones |

---

## Troubleshooting

### "Not logged in" on Profile
Close and reopen the app. Firebase auth session restores automatically on restart.

### Google Sign-In not working
Make sure you have a Google account set up on your device and Google Play Services is up to date.

### Proof photo not uploading
- Check your internet connection
- Make sure the photo is under 5 MB
- Only image files (JPEG, PNG) are supported

### Not receiving notifications
1. Go to phone Settings > Apps > HabitBet > Notifications
2. Make sure notifications are enabled
3. Check that battery optimization is not blocking the app

### Challenge not showing on Arbitrate tab
The arbiter must sign in with the same email that the challenge creator entered. Check the arbiter email matches exactly.

---

## Privacy & Data

- Your data is stored securely in Firebase (Google Cloud)
- Proof photos are stored in Firebase Storage
- Only you and your arbiter can see your challenge proofs
- You can sign out at any time from the Profile tab
- Account deletion: contact support

---
---

# HabitBet - Посібник користувача

## Що таке HabitBet?

HabitBet — це додаток для формування звичок, де ви ставите реальні гроші на свої цілі. Створіть челендж, запросіть друга як арбітра, і щодня доводьте, що дотримуєтесь своєї звички. Виконали челендж — гроші залишаються у вас. Не впорались — гроші йдуть на благодійність.

---

## Початок роботи

### 1. Вхід

Відкрийте додаток і натисніть **"Continue with Google"** (або **"Continue with Apple"** на iOS). Акаунт створюється автоматично.

### 2. Головний екран

Після входу ви побачите головний екран з трьома вкладками:

| Вкладка | Опис |
|---------|------|
| **My Challenges** | Челенджі, які ви створили |
| **Arbitrate** | Челенджі, де ви арбітр (суддя) |
| **Profile** | Ваша статистика, налаштування та вихід |

---

## Створення челенджу

1. Натисніть кнопку **"+"** на головному екрані
2. Заповніть деталі челенджу:

| Поле | Опис | Приклад |
|------|------|---------|
| **Title** | Коротка назва челенджу | "Ранковий біг 5 км" |
| **Description** | Що саме рахується як виконання завдання | "Пробігти мінімум 5 км до 9:00, скріншот з бігової програми як доказ" |
| **Duration** | Скільки днів триває челендж (7-90) | 21 день |
| **Days per week** | Скільки днів на тиждень потрібно виконувати завдання | 5 днів/тиждень |
| **Stake amount** | Сума ставки ($5 - $500) | $25 |
| **Charity** | Куди підуть гроші у разі провалу | Red Cross, UNICEF, WWF або Doctors Without Borders |
| **Arbiter name** | Ім'я друга, який буде оцінювати докази | "Іван" |
| **Arbiter email** | Його email (потрібен акаунт HabitBet) | "ivan@email.com" |

3. Натисніть **"Create Challenge"**
4. Челендж починається наступного дня

---

## Щоденна рутина

### Подання доказів

Щодня протягом челенджу:

1. Перейдіть у **My Challenges** і натисніть на активний челендж
2. Знайдіть сьогоднішню дату в календарі
3. Натисніть **"Submit Proof"**
4. Зробіть фото або виберіть з галереї — це ваш доказ
5. Додайте необов'язковий коментар з поясненням
6. Натисніть **"Submit"**

Ваш доказ буде відправлено арбітру на перевірку.

### Дедлайни

- Доказ потрібно подати до **23:59** в день завдання
- Якщо ви пропустите дедлайн, день позначається як **пропущений**
- О **20:00** ви отримаєте нагадування, якщо ще не подали доказ

---

## Статуси доказів

Кожен день вашого челенджу має один із цих статусів:

| Статус | Іконка | Значення |
|--------|--------|----------|
| **Pending** | Сіре коло | Доказ ще не подано, є час |
| **Submitted** | Жовте коло | Доказ відправлено, очікує перевірки арбітром |
| **Approved** | Зелена галочка | Арбітр підтвердив доказ |
| **Rejected** | Червоний хрестик | Арбітр відхилив доказ (з поясненням) |
| **Missed** | Червоне коло | Дедлайн минув без доказу |

---

## Роль арбітра

Якщо друг запросив вас як арбітра:

1. Перейдіть на вкладку **Arbitrate**
2. Ви побачите челенджі, які чекають на вашу перевірку
3. Натисніть на челендж, щоб побачити подані докази
4. Для кожного доказу ви можете:
   - **Approve** — доказ валідний, день зараховано
   - **Reject** — доказ недостатній (потрібно вказати причину)

### Рекомендації для арбітра

- Будьте чесними та послідовними
- Перевіряйте докази вчасно (ваш друг на вас розраховує)
- Підтверджуйте лише ті докази, які дійсно відповідають критеріям челенджу
- При відхиленні поясніть причину, щоб друг знав, що покращити

---

## Результати челенджу

### Челендж виконано

Якщо ви набрали потрібну кількість днів:
- Челендж позначається як **completed** (виконаний)
- Ваша ставка повертається (гроші не списуються)
- Статистика профілю оновлюється

### Челендж провалено

Якщо ви не набрали потрібну кількість днів:
- Челендж позначається як **failed** (провалений)
- Ваша ставка йде на обрану благодійну організацію
- Статистика профілю оновлюється

### Як рахуються дні

Додаток визначає успіх на основі:
- **Duration**: загальна кількість днів челенджу
- **Required days per week**: скільки днів на тиждень ви зобов'язались виконувати
- **Загальна кількість потрібних днів** = (тривалість / 7) x днів на тиждень (округлення вгору)
- Якщо **підтверджені дні >= потрібна кількість днів** — ви виграли

**Приклад**: челендж на 21 день, 5 днів/тиждень = потрібно мінімум 15 підтверджених днів.

---

## Профіль і статистика

Ваш профіль показує:

| Показник | Опис |
|----------|------|
| **Created** | Загальна кількість створених челенджів |
| **Completed** | Успішно завершені челенджі |
| **Failed** | Незавершені челенджі |
| **Total Staked** | Загальна сума поставлених грошей |
| **Lost to Charity** | Загальна сума, що пішла на благодійність |

---

## Сповіщення

HabitBet надсилає push-сповіщення:

- **Щоденне нагадування** (20:00) — якщо ви ще не подали доказ за сьогодні
- **Доказ подано** — арбітр отримує сповіщення, коли ви подаєте доказ
- **Оновлення челенджу** — зміни статусу ваших челенджів

Переконайтесь, що сповіщення для HabitBet увімкнені в налаштуваннях телефону.

---

## Поради для успіху

1. **Починайте з малого** — спробуйте 7-денний челендж для початку
2. **Оберіть надійного арбітра** — того, хто перевірятиме докази щодня
3. **Встановіть рутину** — виконуйте завдання і подавайте доказ в один і той самий час
4. **Не ігноруйте нагадування** — зверніть увагу на сповіщення о 20:00
5. **Будьте конкретними** — напишіть чіткий опис, щоб арбітр точно знав, що підтверджувати
6. **Робіть якісні фото** — має бути очевидно, що завдання виконано

---

## Підтримувані благодійні організації

| Організація | Опис |
|-------------|------|
| **Red Cross** | Гуманітарна допомога по всьому світу |
| **UNICEF** | Допомога дітям та освіта |
| **WWF** | Захист дикої природи та довкілля |
| **Doctors Without Borders** | Медична допомога в зонах кризи |

---

## Вирішення проблем

### "Not logged in" у профілі
Закрийте і знову відкрийте додаток. Сесія Firebase Auth відновлюється автоматично при перезапуску.

### Google Sign-In не працює
Переконайтесь, що на вашому пристрої налаштовано Google-акаунт і Google Play Services оновлено до останньої версії.

### Фото доказу не завантажується
- Перевірте інтернет-з'єднання
- Фото має бути менше 5 МБ
- Підтримуються лише зображення (JPEG, PNG)

### Не приходять сповіщення
1. Перейдіть у Налаштування телефону > Додатки > HabitBet > Сповіщення
2. Переконайтесь, що сповіщення увімкнені
3. Перевірте, чи не блокує додаток оптимізація батареї

### Челендж не відображається у вкладці Arbitrate
Арбітр повинен увійти з тим самим email, який вказав творець челенджу. Перевірте, чи email збігається точно.

---

## Конфіденційність та дані

- Ваші дані зберігаються безпечно у Firebase (Google Cloud)
- Фото доказів зберігаються у Firebase Storage
- Тільки ви та ваш арбітр можете бачити докази челенджу
- Ви можете вийти з акаунта будь-коли через вкладку Profile
- Видалення акаунта: зверніться до підтримки
