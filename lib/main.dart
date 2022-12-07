import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

@immutable
class Film {
  final String id;
  final String title;
  final String description;
  final bool isFavorited;
  const Film({
    required this.id,
    required this.title,
    required this.description,
    required this.isFavorited,
  });

  Film copyWith({bool? isFavorited}) {
    return Film(
      id: id,
      title: title,
      description: description,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  @override
  String toString() =>
      'Film(id: $id, title: $title, description: $description)';

  @override
  bool operator ==(covariant Film other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.description == description;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ description.hashCode;
}

const films = [
  Film(
      id: "1",
      title: "GodFather",
      description: "GodFather I",
      isFavorited: false),
  Film(
      id: "2",
      title: "GodFather II",
      description: "GodFather II",
      isFavorited: true)
];

enum FavoriteStatusFilm { all, favorite, notFavorite }

class FilmProvider extends StateNotifier<List<Film>> {
  FilmProvider() : super(films);

  void update(Film film, bool isFavorited) {
    state = state
        .map((thisFilm) => thisFilm.id == film.id
            ? thisFilm.copyWith(isFavorited: isFavorited)
            : thisFilm)
        .toList();
  }
}

final statusFilmProvider = StateProvider<FavoriteStatusFilm>(
  (ref) {
    return FavoriteStatusFilm.all;
  },
);

final allFilmsProvider = StateNotifierProvider<FilmProvider, Iterable<Film>>(
  (ref) {
    return FilmProvider();
  },
);

final favoriteFilmProvider = StateProvider<Iterable<Film>>(
  (ref) {
    return ref.watch(allFilmsProvider).where((element) => element.isFavorited);
  },
);

final notFavoriteFilmProvider = StateProvider<Iterable<Film>>(
  (ref) {
    return ref.watch(allFilmsProvider).where((element) => !element.isFavorited);
  },
);

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final status = ref.watch(statusFilmProvider);
          switch (status) {
            case FavoriteStatusFilm.notFavorite:
              return FilmsWidget(provider: notFavoriteFilmProvider);
            case FavoriteStatusFilm.favorite:
              return FilmsWidget(provider: favoriteFilmProvider);
            case FavoriteStatusFilm.all:
            default:
              return FilmsWidget(provider: allFilmsProvider);
          }
        },
      ),
    );
  }
}

class FilmsWidget extends ConsumerWidget {
  const FilmsWidget({super.key, required this.provider});
  final AlwaysAliveProviderBase<Iterable<Film>> provider;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const FilterWidget(),
        Consumer(
          builder: (context, ref, child) {
            final listFilm = ref.watch(provider);
            return Expanded(
              child: ListView.builder(
                itemCount: listFilm.length,
                itemBuilder: (context, index) {
                  final film = listFilm.elementAt(index);
                  final isFavorited = film.isFavorited
                      ? const Icon(Icons.favorite)
                      : const Icon(Icons.favorite_border);
                  return ListTile(
                    title: Text(film.title),
                    subtitle: Text(film.description),
                    trailing: isFavorited,
                    onTap: () {
                      ref.read(allFilmsProvider.notifier).update(
                            film,
                            !film.isFavorited,
                          );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class FilterWidget extends StatelessWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return DropdownButton(
          value: ref.watch(statusFilmProvider),
          items: FavoriteStatusFilm.values.map((fs) {
            return DropdownMenuItem<FavoriteStatusFilm>(
              value: fs,
              child: Text(
                fs.name,
              ),
            );
          }).toList(),
          onChanged: (value) {
            ref.read(statusFilmProvider.notifier).state = value!;
          },
        );
      },
    );
  }
}
