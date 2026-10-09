import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const supabaseUrl = 'https://yrwsvmojkirlapvraqhj.supabase.co';
const supabaseKey = 'sb_publishable_G3L5sVOtPn_TnTXVysNJTA_tEamz2hO';

const authUrl = '$supabaseUrl/auth/v1';
const eventsUrl = '$supabaseUrl/rest/v1/events';

// K3 - Modeli
class Session {
  final String accessToken;
  final String userId;
  final String email;

  const Session({
    required this.accessToken,
    required this.userId,
    required this.email,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      accessToken: json['access_token'] as String,
      userId: json['user']['id'] as String,
      email: json['user']['email'] as String,
    );
  }
}

Session? currentSession;

// K3 - Modeli
class Event {
  final int id;
  final String title;
  final String date;
  final String location;
  final int likes;
  final String? userId;
  final String? author;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.likes,
    required this.userId,
    required this.author,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String,
      date: json['date'] as String,
      location: json['location'] as String,
      likes: (json['likes'] ?? 0) as int,
      userId: json['user_id'] as String?,
      author: json['author'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isMine => userId == currentSession?.userId;
}

// Headers me token
Map<String, String> authHeaders() {
  final headers = <String, String>{
    'apikey': supabaseKey,
    'Content-Type': 'application/json',
  };

  if (currentSession != null) {
    headers['Authorization'] = 'Bearer ${currentSession!.accessToken}';
  }

  return headers;
}

String apiError(http.Response response) {
  try {
    final data = jsonDecode(response.body);
    return (data['msg'] ??
            data['message'] ??
            data['error_description'] ??
            data['error'] ??
            'Gabim ${response.statusCode}')
        .toString();
  } catch (_) {
    return 'Gabim ${response.statusCode}: ${response.body}';
  }
}

// K7 - Login/regjistrim
Future<Session> signUp(String email, String password) async {
  final response = await http.post(
    Uri.parse('$authUrl/signup'),
    headers: authHeaders(),
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(apiError(response));
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;

  if (data['access_token'] == null) {
    throw Exception(
      'Regjistrimi u krye, por nuk u krijua sesion. Kontrollo Confirm email në Supabase.',
    );
  }

  return Session.fromJson(data);
}

// K7 - Login/regjistrim
Future<Session> signIn(String email, String password) async {
  final response = await http.post(
    Uri.parse('$authUrl/token?grant_type=password'),
    headers: authHeaders(),
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(apiError(response));
  }

  return Session.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );
}

// K17 - Dalja
Future<void> signOut() async {
  if (currentSession == null) return;

  await http.post(
    Uri.parse('$authUrl/logout'),
    headers: authHeaders(),
  );
}

// K4 + K14 - Leximi dhe filtrimi
Future<List<Event>> fetchEvents({bool onlyMine = false}) async {
  var url = '$eventsUrl?select=*&order=created_at.desc';

  if (onlyMine && currentSession != null) {
    url += '&user_id=eq.${currentSession!.userId}';
  }

  final response = await http.get(
    Uri.parse(url),
    headers: authHeaders(),
  );

  if (response.statusCode != 200) {
    throw Exception(apiError(response));
  }

  final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;

  return rows
      .map(
        (row) => Event.fromJson(row as Map<String, dynamic>),
      )
      .toList();
}

// K10 - Shtimi
Future<void> addEvent({
  required String title,
  required String date,
  required String location,
}) async {
  final response = await http.post(
    Uri.parse(eventsUrl),
    headers: authHeaders(),
    body: jsonEncode({
      'title': title,
      'date': date,
      'location': location,
      'author': currentSession!.email,
    }),
  );

  if (response.statusCode != 201) {
    throw Exception(apiError(response));
  }
}

// K11 - Ndryshimi vetëm nga pronari
Future<void> updateEvent({
  required int id,
  required String title,
  required String date,
  required String location,
}) async {
  final response = await http.patch(
    Uri.parse('$eventsUrl?id=eq.$id'),
    headers: authHeaders(),
    body: jsonEncode({
      'title': title,
      'date': date,
      'location': location,
    }),
  );

  if (response.statusCode != 204) {
    throw Exception(apiError(response));
  }
}

// K12 - Fshirja vetëm nga pronari
Future<void> deleteEvent(int id) async {
  final response = await http.delete(
    Uri.parse('$eventsUrl?id=eq.$id'),
    headers: authHeaders(),
  );

  if (response.statusCode != 204) {
    throw Exception(apiError(response));
  }
}

void main() {
  runApp(const MyApp());
}

// K15 - Tema/dark mode
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _darkMode = false;

  void _setDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
  }

  void _onLogin(Session session) {
    setState(() {
      currentSession = session;
    });
  }

  Future<void> _onLogout() async {
    await signOut();

    if (!mounted) return;

    setState(() {
      currentSession = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BGT Campus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: currentSession == null
          ? LoginPage(onLogin: _onLogin)
          : HomeShell(
              darkMode: _darkMode,
              onDarkModeChanged: _setDarkMode,
              onLogout: _onLogout,
            ),
    );
  }
}

// K7 - Login/regjistrim
class LoginPage extends StatefulWidget {
  final ValueChanged<Session> onLogin;

  const LoginPage({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validate(String email, String password) {
    if (!email.contains('@')) {
      return 'Shkruani një email të vlefshëm.';
    }

    if (password.length < 6) {
      return 'Fjalëkalimi duhet të ketë së paku 6 karaktere.';
    }

    return null;
  }

  Future<void> _submit({required bool register}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final validation = _validate(email, password);

    if (validation != null) {
      setState(() {
        _error = validation;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = register
          ? await signUp(email, password)
          : await signIn(email, password);

      if (!mounted) return;
      widget.onLogin(session);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BGT Campus'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Icon(Icons.school, size: 72),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Fjalëkalimi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 14),
                if (_loading)
                  const CircularProgressIndicator()
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _submit(register: false),
                      child: const Text('Kyçu'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _submit(register: true),
                      child: const Text('Regjistrohu'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// K16 - Navigimi me 3+ tab-a
class HomeShell extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLogout;

  const HomeShell({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onLogout,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const EventsPage(),
      ProfilePage(
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ['Home', 'Events', 'Profile'][_index],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// K1 - Plani i projektit reflektohet edhe në README
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mirë se vini',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  currentSession?.email ?? '',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mini-projekti final i Day 5 për menaxhimin e eventeve të kampusit.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Funksionet kryesore'),
            subtitle: Text(
              'Login/regjistrim, CRUD i eventeve, RLS, listë live, filtrim, dark mode dhe profil.',
            ),
          ),
        ),
      ],
    );
  }
}

// K5 + K6 + K13 + K14
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _controller = StreamController<List<Event>>();

  Timer? _timer;
  bool _onlyMine = false;

  Future<void> _load() async {
    try {
      final events = await fetchEvents(
        onlyMine: _onlyMine,
      );

      if (!_controller.isClosed) {
        _controller.add(events);
      }
    } catch (e) {
      if (!_controller.isClosed) {
        _controller.addError(e);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _load();

    // K13 - Lista live
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _load(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
    super.dispose();
  }

  Future<void> _openCreateForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EventFormPage(),
      ),
    );

    if (saved == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add),
        label: const Text('Shto event'),
      ),
      body: Column(
        children: [
          // K14 - Filtrimi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Të gjitha'),
                  selected: !_onlyMine,
                  onSelected: (_) {
                    setState(() {
                      _onlyMine = false;
                    });
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Të miat'),
                  selected: _onlyMine,
                  onSelected: (_) {
                    setState(() {
                      _onlyMine = true;
                    });
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: _controller.stream,
              builder: (context, snapshot) {
                // K6 - 1) error
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gabim gjatë ngarkimit:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // K6 - 2) loading
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final events = snapshot.data!;

                // K6 - 3) empty
                if (events.isEmpty) {
                  return const Center(
                    child: Text('Nuk ka evente për të shfaqur.'),
                  );
                }

                // K5 + K6 - 4) data
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 90,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            event.isMine
                                ? Icons.person
                                : Icons.event,
                          ),
                          title: Text(event.title),
                          subtitle: Text(
                            '${event.date} • ${event.location}\n'
                            'Nga: ${event.author ?? "pa autor"}',
                          ),
                          isThreeLine: true,
                          trailing: event.isMine
                              ? const Icon(Icons.chevron_right)
                              : null,
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailPage(
                                  event: event,
                                ),
                              ),
                            );

                            if (changed == true) {
                              await _load();
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// K8 - Detajet
class EventDetailPage extends StatelessWidget {
  final Event event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  Future<void> _edit(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormPage(
          event: event,
        ),
      ),
    );

    if (changed == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Fshije eventin?'),
          content: Text(
            'A jeni të sigurt që dëshironi ta fshini "${event.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Jo'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Po, fshije'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await deleteEvent(event.id);

      if (!context.mounted) return;

      // K18 - SnackBar/feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eventi u fshi.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detajet e eventit'),
        actions: [
          if (event.isMine)
            IconButton(
              tooltip: 'Ndrysho',
              onPressed: () => _edit(context),
              icon: const Icon(Icons.edit),
            ),
          if (event.isMine)
            IconButton(
              tooltip: 'Fshi',
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            event.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Data'),
            subtitle: Text(event.date),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Lokacioni'),
            subtitle: Text(event.location),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Autori'),
            subtitle: Text(event.author ?? 'Pa autor'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Pëlqime'),
            subtitle: Text('${event.likes}'),
          ),
          if (event.isMine)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Ky event është i juaji. Mund ta ndryshoni ose fshini.',
              ),
            ),
        ],
      ),
    );
  }
}

// K9 + K10 + K11
class EventFormPage extends StatefulWidget {
  final Event? event;

  const EventFormPage({
    super.key,
    this.event,
  });

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  late final TextEditingController _locationController;

  bool _saving = false;

  bool get _editing => widget.event != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.event?.title ?? '',
    );
    _dateController = TextEditingController(
      text: widget.event?.date ?? '',
    );
    _locationController = TextEditingController(
      text: widget.event?.location ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kjo fushë është e obligueshme.';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_editing) {
        // K11 - vetëm pronari e sheh formën e editimit
        await updateEvent(
          id: widget.event!.id,
          title: _titleController.text.trim(),
          date: _dateController.text.trim(),
          location: _locationController.text.trim(),
        );
      } else {
        // K10
        await addEvent(
          title: _titleController.text.trim(),
          date: _dateController.text.trim(),
          location: _locationController.text.trim(),
        );
      }

      if (!mounted) return;

      // K18 - SnackBar/feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing ? 'Eventi u ndryshua.' : 'Eventi u shtua.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing && widget.event!.isMine == false) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ndrysho eventin'),
        ),
        body: const Center(
          child: Text(
            'Nuk keni leje ta ndryshoni këtë event.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'Ndrysho eventin' : 'Shto event',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Titulli',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dateController,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Data',
                hintText: 'p.sh. 20.10.2026',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationController,
              validator: _requiredValidator,
              decoration: const InputDecoration(
                labelText: 'Lokacioni',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Duke ruajtur...'
                    : (_editing ? 'Ruaj ndryshimet' : 'Shto eventin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// K15 + K17
class ProfilePage extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final email = currentSession?.email ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 42,
          child: Icon(
            Icons.person,
            size: 42,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            email,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          value: darkMode,
          onChanged: onDarkModeChanged,
          title: const Text('Dark mode'),
          secondary: const Icon(Icons.dark_mode),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Dil nga llogaria'),
          onTap: onLogout,
        ),
      ],
    );
  }
}
