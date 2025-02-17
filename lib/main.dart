// Flutter CRUD para gerenciamento de planetas utilizando SQLite
// Segue o padrão MVC para melhor organização e manutenção do código
// Implementa todas as funcionalidades de Create, Read, Update e Delete (CRUD)

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

// Modelo de Planeta - Representa os dados de um planeta no sistema
class Planet {
  int? id;
  String name; // Nome do planeta (Campo obrigatório)
  double distanceFromSun; // Distância do planeta ao sol (UA - Unidades Astronômicas) (Campo obrigatório)
  double size; // Tamanho do planeta em quilômetros (Campo obrigatório)
  String? nickname; // Apelido do planeta (opcional)
  String description; // Descrição do planeta

  Planet({
    this.id,
    required this.name,
    required this.distanceFromSun,
    required this.size,
    this.nickname,
    required this.description,
  });

  // Converte um objeto Planeta em um mapa para ser salvo no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'distanceFromSun': distanceFromSun,
      'size': size,
      'nickname': nickname,
      'description': description,
    };
  }
}

// Classe responsável pelo banco de dados SQLite
class PlanetDatabase {
  // Criação da base de dados e da tabela de planetas
  static Future<Database> database() async {
    return openDatabase(
      join(await getDatabasesPath(), 'planets_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE planets(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, distanceFromSun REAL, size REAL, nickname TEXT, description TEXT)'
        );
      },
      version: 1,
    );
  }

  // Função para inserir um novo planeta no banco de dados (Create)
  static Future<void> insertPlanet(Planet planet) async {
    final db = await database();
    try {
      await db.insert('planets', planet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } finally {
      await db.close();
    }
  }

  // Função para obter a lista de planetas cadastrados (Read)
  static Future<List<Planet>> getPlanets() async {
    final db = await database();
    try {
      final List<Map<String, dynamic>> maps = await db.query('planets');
      return List.generate(maps.length, (i) {
        return Planet(
          id: maps[i]['id'],
          name: maps[i]['name'],
          distanceFromSun: maps[i]['distanceFromSun'],
          size: maps[i]['size'],
          nickname: maps[i]['nickname'],
          description: maps[i]['description'],
        );
      });
    } finally {
      await db.close();
    }
  }

  // Função para atualizar os dados de um planeta cadastrado (Update)
  static Future<void> updatePlanet(Planet planet) async {
    final db = await database();
    try {
      await db.update('planets', planet.toMap(), where: 'id = ?', whereArgs: [planet.id]);
    } finally {
      await db.close();
    }
  }

  // Função para excluir um planeta do banco de dados (Delete)
  static Future<void> deletePlanet(int id) async {
    final db = await database();
    try {
      await db.delete('planets', where: 'id = ?', whereArgs: [id]);
    } finally {
      await db.close();
    }
  }
}

// Tela inicial do aplicativo
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planetas CRUD',
      home: PlanetListScreen(),
    );
  }
}

// Tela que exibe a lista de planetas cadastrados
class PlanetListScreen extends StatefulWidget {
  @override
  _PlanetListScreenState createState() => _PlanetListScreenState();
}

class _PlanetListScreenState extends State<PlanetListScreen> {
  List<Planet> planets = [];

  @override
  void initState() {
    super.initState();
    _loadPlanets();
  }

  // Carrega a lista de planetas do banco de dados
  Future<void> _loadPlanets() async {
    final loadedPlanets = await PlanetDatabase.getPlanets();
    setState(() {
      planets = loadedPlanets;
    });
  }

  // Exclui um planeta e atualiza a interface
  void _deletePlanet(int id) async {
    await PlanetDatabase.deletePlanet(id);
    _loadPlanets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Planetas')),
      body: ListView.builder(
        itemCount: planets.length,
        itemBuilder: (context, index) {
          final planet = planets[index];
          return ListTile(
            title: Text(planet.name),
            subtitle: Text(planet.nickname ?? 'Sem apelido'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePlanet(planet.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlanetFormScreen()),
          );
          _loadPlanets();
        },
        child: Icon(Icons.add), // Botão para adicionar novos planetas
      ),
    );
  }
}

// Tela para adicionar ou editar um planeta
class PlanetFormScreen extends StatefulWidget {
  @override
  _PlanetFormScreenState createState() => _PlanetFormScreenState();
}

class _PlanetFormScreenState extends State<PlanetFormScreen> {
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Salva um novo planeta no banco de dados
  void _savePlanet() async {
    final newPlanet = Planet(
      name: _nameController.text,
      distanceFromSun: double.parse(_distanceController.text),
      size: double.parse(_sizeController.text),
      nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
      description: _descriptionController.text,
    );
    await PlanetDatabase.insertPlanet(newPlanet);
    Navigator.pop(context as BuildContext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adicionar Planeta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Nome')), // Campo obrigatório
            TextField(controller: _distanceController, decoration: InputDecoration(labelText: 'Distância do Sol (UA)'), keyboardType: TextInputType.number), // Campo obrigatório
            TextField(controller: _sizeController, decoration: InputDecoration(labelText: 'Tamanho (km)'), keyboardType: TextInputType.number), // Campo obrigatório
            TextField(controller: _nicknameController, decoration: InputDecoration(labelText: 'Apelido (opcional)')),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Descrição')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _savePlanet, child: Text('Salvar')),
          ],
        ),
      ),
    );
  }
}     