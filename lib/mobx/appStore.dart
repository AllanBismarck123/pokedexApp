import 'dart:ui';

import 'package:mobx/mobx.dart';
import 'package:pokedex/pokemon.dart';
import '../service/api.dart';

class AppStore {
  List<Pokemon> content = [];

  List<String> generation = <String>[
    '1ª',
    '2ª',
    '3ª',
    '4ª',
    '5ª',
    '6ª',
    '7ª',
    '8ª',
  ];

  var tempSelectedGeneration = <bool>[
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  var selectedGeneration = Observable<List<bool>>(
      [false, false, false, false, false, false, false, false]);

  List<String> type = <String>[
    'Normal',
    'Luta',
    'Vôo',
    'Veneno',
    'Terra',
    'Pedra',
    'Inseto',
    'Fantasma',
    'Aço',
    'Fogo',
    'Água',
    'Grama',
    'Elétrico',
    'Psíquico',
    'Gelo',
    'Dragão',
    'Trevas',
    'Fada',
    'Desconhecido',
    'Sombra',
  ];

  var tempSelectedType = <bool>[
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  var selectedType = Observable<List<bool>>([
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ]);

  late final setToggle = Action(_setToggle);

  List<bool> returnToggleButtonsSelecteds() {
    bool isSelectedType = false;
    bool isSelectedGeneration = false;

    for (int x = 0; x < generation.length; x++) {
      if (selectedGeneration.value[x] == true) {
        isSelectedGeneration = true;
        break;
      }
    }

    for (int x = 0; x < type.length; x++) {
      if (selectedType.value[x] == true) {
        isSelectedType = true;
        break;
      }
    }

    return [isSelectedGeneration, isSelectedType];
  }

  Future<List<Pokemon>> pokemonSearchByToggleButtons() async {
    var contentGeneration = [], contentType = [], contentTemp;
    content = [];

    for (int x = 0; x < generation.length; x++) {
      if (selectedGeneration.value[x] == true) {
        contentTemp = await api().myRequest('generation/${x + 1}/');
        contentTemp = contentTemp['pokemon_species'];
        contentGeneration += contentTemp;
      }
    }

    for (int x = 0; x < type.length; x++) {
      if (selectedType.value[x] == true) {
        if (x == 18) {
          contentTemp = await api().myRequest('type/10001/');
        } else {
          if (x == 19) {
            contentTemp = await api().myRequest('type/10002/');
          } else {
            contentTemp = await api().myRequest('type/${x + 1}/');
          }
        }
        contentTemp = contentTemp['pokemon'];
        contentTemp = formatListPokemonByType(contentTemp);
        contentType += contentTemp;
      }
    }

    contentTemp = [];
    for (int x = 0; x < contentGeneration.length; x++) {
      for (int y = 0; y < contentType.length; y++) {
        if (contentGeneration[x]['name'] == contentType[y]['name']) {
          contentTemp.add(contentGeneration[x]['name']);
        }
      }
    }
    contentTemp = removeRepetiblePokemonList(contentTemp);
    contentTemp.sort();
    content = await mapNameforPokemon(contentTemp);
    return content;
  }

  Future<List<Pokemon>> pokemonSearchByWord(word) async {
    var temp;
    temp = await api().myRequest('pokemon/$word');
    if (temp == null) {
      return [Pokemon()];
    } else {
      temp = temp['forms'];
      temp = [temp[0]['name']];
      content = await mapNameforPokemon(temp);
      return content;
    }
  }

  extractNamesFromPokemons(list) {
    var temp = [];
    for (int x = 0; x < list.length; x++) {
      temp.add(list[x]['name']);
    }
    return temp;
  }

  formatListPokemonByType(content) {
    List<dynamic> temp = [];
    for (int index = 0; index < content.length; index++) {
      temp.add(content[index]['pokemon']);
    }
    return temp;
  }

  extractPokemonsFromSpecies(content) async {
    List<dynamic> temp = [];
    var pokemons;
    for (int index = 0; index < content.length; index++) {
      pokemons = await api().myRequest(content[index]['url'].substring(26));
      pokemons = pokemons['varieties'];
      pokemons = formatListPokemonByType(pokemons);
      for (int i = 0; i < pokemons.length; i++) {
        temp.add(pokemons[i]);
      }
    }
    return temp;
  }

  mapNameforPokemon(listPokemon) async {
    List<Pokemon> pokemons = [];
    for (int index = 0; index < listPokemon.length; index++) {
      var temp = await getPokemonDetails(listPokemon[index]);
      if (temp != null) {
        pokemons.add(temp);
      }
    }
    return pokemons;
  }

  removeRepetiblePokemonList(list) {
    for (int x = 0; x < list.length; x++) {
      for (int y = 0; y < list.length; y++) {
        if (x != y && list[x] == list[y]) {
          list.remove(list[y]);
        }
      }
    }
    return list;
  }

  selectedItens(itemSelected) {
    if (itemSelected.contains(RegExp(r'[0-9]'))) {
      for (int x = 0; x < generation.length; x++) {
        if (itemSelected == generation[x]) {
          tempSelectedGeneration[x] = !tempSelectedGeneration[x];
          setToggle();
        }
      }
    } else {
      for (int x = 0; x < type.length; x++) {
        if (itemSelected == type[x]) {
          tempSelectedType[x] = !tempSelectedType[x];
          setToggle();
        }
      }
    }
  }

  getPokemonDetails(item) async {
    var pokemon = Pokemon();
    var geralPokemon = await api().myRequest('pokemon-form/$item');
    if (geralPokemon != null) {
      pokemon.name = geralPokemon['name'];
      pokemon.types = extractTypesFromPokemon(geralPokemon['types']);
      pokemon.sprites = geralPokemon['sprites']['front_default'];
      pokemon.color = getColor(pokemon.types);
      return pokemon;
    }

    return null;
  }

  extractTypesFromPokemon(types) {
    String strType = '';
    for (int index = 0; index < types.length; index++) {
      strType += translateType(types[index]['type']['name']);
      strType += ' | ';
    }
    strType = strType.substring(0, strType.length - 3);
    return strType;
  }

  translateType(type) {
    switch (type) {
      case 'normal':
        return 'Normal';
      case 'fighting':
        return 'Luta';
      case 'flying':
        return 'Vôo';
      case 'poison':
        return 'Veneno';
      case 'ground':
        return 'Terra';
      case 'rock':
        return 'Pedra';
      case 'bug':
        return 'Inseto';
      case 'ghost':
        return 'Fantasma';
      case 'steel':
        return 'Aço';
      case 'fire':
        return 'Fogo';
      case 'water':
        return 'Água';
      case 'grass':
        return 'Grama';
      case 'electric':
        return 'Elétrico';
      case 'psychic':
        return 'Psíquico';
      case 'ice':
        return 'Gelo';
      case 'dragon':
        return 'Dragão';
      case 'dark':
        return 'Trevas';
      case 'fairy':
        return 'Fada';
      case 'unknown':
        return 'Desconhecido';
      case 'shadow':
        return 'Sombra';
      default:
        return 'nothing';
    }
  }

  getColor(type) {
    var temp = type.split(' | ');
    switch (temp[0]) {
      case 'Normal':
        return Color.fromARGB(255, 238, 238, 238);
      case 'Luta':
        return Color.fromARGB(255, 195, 201, 217);
      case 'Vôo':
        return Color.fromARGB(255, 248, 244, 171);
      case 'Veneno':
        return Color.fromARGB(255, 196, 5, 199);
      case 'Terra':
        return Color.fromARGB(255, 166, 99, 60);
      case 'Pedra':
        return Color.fromARGB(255, 222, 184, 135);
      case 'Inseto':
        return Color.fromARGB(255, 144, 238, 144);
      case 'Fantasma':
        return Color.fromARGB(255, 164, 86, 166);
      case 'Aço':
        return Color.fromARGB(255, 219, 221, 227);
      case 'Fogo':
        return Color.fromARGB(255, 255, 165, 0);
      case 'Água':
        return Color.fromARGB(255, 62, 159, 255);
      case 'Grama':
        return Color.fromARGB(255, 8, 231, 8);
      case 'Elétrico':
        return Color.fromARGB(255, 255, 255, 0);
      case 'Psíquico':
        return Color.fromARGB(255, 255, 238, 137);
      case 'Gelo':
        return Color.fromARGB(255, 165, 229, 255);
      case 'Dragão':
        return Color.fromARGB(255, 236, 55, 55);
      case 'Trevas':
        return Color.fromARGB(255, 122, 122, 122);
      case 'Fada':
        return Color.fromARGB(255, 255, 182, 193);
      case 'Desconhecido':
        return Color.fromARGB(255, 182, 191, 147);
      case 'Sombra':
        return Color.fromARGB(255, 211, 211, 211);
      default:
        return Color.fromARGB(255, 255, 0, 255);
    }
  }

  _setToggle() {
    selectedGeneration.value = tempSelectedGeneration;
    selectedType.value = tempSelectedType;
  }
}
