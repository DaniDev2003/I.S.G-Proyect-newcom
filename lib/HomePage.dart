import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _currentIndex = 0;

  List<Map<String, dynamic>> jugadores = [];
  bool _deleteMode = false;
  final Set<int> _seleccionados = <int>{};


  List<Map<String, dynamic>> equiposVisuales = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadJugadores();
  }

  //eliminar jugador de la lista global
  void _eliminarSeleccionados() {
    if (_seleccionados.isEmpty) return; // no hay nada que borrar

    // Construimos la lista de nombres seleccionados
    final seleccionadosNombres = _seleccionados
        .map((i) => jugadores[i]["nombre"] ?? "Jugador $i")
        .join(", ");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar eliminación"),
          content: Text(
            "¿Está seguro de eliminar a los siguientes jugadores?\n\n$seleccionadosNombres",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // cancelar
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // cerrar diálogo
                setState(() {
                  jugadores = jugadores
                      .asMap()
                      .entries
                      .where((entry) => !_seleccionados.contains(entry.key))
                      .map((entry) => entry.value)
                      .toList();

                  _seleccionados.clear();
                  _deleteMode = false;
                });

                await _saveJugadores();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------- SharedPreferences ----------------------

  Future<void> _loadJugadores() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('jugadores');
    if (jsonStr != null) {
      final List<dynamic> data = jsonDecode(jsonStr);
      setState(() {
        jugadores = data.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveJugadores() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(jugadores);
    await prefs.setString('jugadores', jsonStr);
  }

  // ---------------------- Navegación ----------------------

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ---------------------- Funciones para agregar jugadores (lista global y partida) ----------------------

  void _agregarJugador() {
    String nombre = '';
    String genero = 'Hombre';
    String rol = 'Atacante';
    int edad = 0;
    int calificacion = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Agregar Jugador'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      onChanged: (value) => nombre = value.trim(),
                    ),
                    DropdownButtonFormField<String>(
                      value: genero,
                      decoration: const InputDecoration(labelText: 'Género'),
                      items: const [
                        DropdownMenuItem(value: 'Hombre', child: Text('Hombre ♂')),
                        DropdownMenuItem(value: 'Mujer', child: Text('Mujer ♀')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          genero = value!;
                        });
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Edad'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        edad = int.tryParse(value) ?? 0;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: rol,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(value: 'Atacante', child: Text('Atacante')),
                        DropdownMenuItem(value: 'Defensor', child: Text('Defensor')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          rol = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < calificacion ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              calificacion = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Guardar'),
                  onPressed: () async {
                    if (nombre.isNotEmpty && edad > 0) {
                      // Verificar si ya existe un jugador con ese nombre
                      bool existe = jugadores.any(
                            (jugador) =>
                        (jugador['nombre'] as String).toLowerCase() ==
                            nombre.toLowerCase(),
                      );

                      if (existe) {
                        // Mostrar alerta de duplicado
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Atención'),
                              content: const Text('¡Ya existe un jugador con ese nombre!'),
                              actions: [
                                TextButton(
                                  child: const Text('Aceptar'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            );
                          },
                        );
                        return; // No seguir guardando
                      }

                      // Si no existe, se agrega normalmente
                      setState(() {
                        jugadores.add({
                          'nombre': nombre,
                          'genero': genero,
                          'edad': edad,
                          'rol': rol,
                          'calificacion': calificacion,
                        });
                      });

                      await _saveJugadores(); // <-- guardar al agregar

                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

// Función para agregar un jugador a la partida comenzada
  void agregarJugadorDialog() {
    final Set<int> seleccionadosDialog = {};

    // Construimos la lista de jugadores en juego a partir de equiposVisuales
    List<Map<String, dynamic>> jugadoresEnJuego = [];
    for (var equipo in equiposVisuales) {
      if (equipo.containsKey('jugadores')) {
        jugadoresEnJuego.addAll(List<Map<String, dynamic>>.from(equipo['jugadores']));
      }
      if (equipo.containsKey('suplentes')) {
        jugadoresEnJuego.addAll(List<Map<String, dynamic>>.from(equipo['suplentes']));
      }
    }

    // Generar un set de claves únicas de jugadores en juego (sin edad)
    Set<String> clavesJugadoresEnJuego = jugadoresEnJuego.map((j) =>
    "${j['nombre']}_${j['rol']}_${j['genero']}"
    ).toSet();

    // Filtrar jugadores que no están en juego (comparando por clave)
    List<Map<String, dynamic>> disponibles = jugadores.where((j) {
      String clave = "${j['nombre']}_${j['rol']}_${j['genero']}";
      return !clavesJugadoresEnJuego.contains(clave);
    }).toList();

    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay jugadores disponibles para agregar.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Agregar jugadores a equipos'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: disponibles.length,
                  itemBuilder: (context, index) {
                    final jugador = disponibles[index];
                    return ListTile(
                      onTap: () {
                        setStateDialog(() {
                          if (seleccionadosDialog.contains(index)) {
                            seleccionadosDialog.remove(index);
                          } else {
                            seleccionadosDialog.add(index);
                          }
                        });
                      },
                      leading: Checkbox(
                        value: seleccionadosDialog.contains(index),
                        onChanged: (value) {
                          setStateDialog(() {
                            if (value == true) {
                              seleccionadosDialog.add(index);
                            } else {
                              seleccionadosDialog.remove(index);
                            }
                          });
                        },
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            jugador['nombre'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${jugador['edad']} años'),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < (jugador['calificacion'] ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${jugador['rol']})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final List<Map<String, dynamic>> jugadoresSeleccionados =
                    seleccionadosDialog.map((i) => disponibles[i]).toList();

                    await asignarSuplentes(jugadoresSeleccionados); // Esperar a que termine

                    Navigator.pop(context); // Cerrar después de todo
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> asignarSuplentes(List<Map<String, dynamic>> jugadoresSeleccionados) async {
    int totalSuplentesActuales = equiposVisuales.fold(0, (sum, eq) => sum + (eq['suplentes'] as List).length);
    int totalSuplentesFinal = totalSuplentesActuales + jugadoresSeleccionados.length;

    if (totalSuplentesFinal >= 6) {
      bool? deseaResortear = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Reorganizar equipos'),
            content: const Text(
                'Al agregar estos jugadores habrá 6 o más suplentes en total.\n'
                    '¿Quieres resortear los equipos creando un equipo extra?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text('Sí, resortear'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          );
        },
      );

      if (deseaResortear == true) {
        // Esperar a que se cierre completamente antes de llamar a selectPlayers
        Future.delayed(Duration.zero, () {
          selectPlayers();
        });

        return;
      }

    }

    for (var suplente in jugadoresSeleccionados) {
      equiposVisuales.sort((a, b) => (a['puntaje'] as int).compareTo(b['puntaje'] as int));
      var equipoMenor = equiposVisuales.first;

      Map<String, int> conteoRoles(Map<String, dynamic> equipo) {
        Map<String, int> conteo = {};
        for (var j in [...equipo['jugadores'], ...equipo['suplentes']]) {
          String rol = j['rol'];
          conteo[rol] = (conteo[rol] ?? 0) + 1;
        }
        return conteo;
      }

      int diff = (equiposVisuales.last['puntaje'] - equiposVisuales.first['puntaje']).abs();
      if (diff <= 1) {
        String rolSuplente = suplente['rol'];
        int minRol = equiposVisuales.map((e) => conteoRoles(e)[rolSuplente] ?? 0).reduce((a, b) => a < b ? a : b);
        for (var eq in equiposVisuales) {
          if ((conteoRoles(eq)[rolSuplente] ?? 0) == minRol) {
            equipoMenor = eq;
            break;
          }
        }
      }

      // 🔁 Intentar swaps múltiples si el puntaje simulado desbalancea
      bool hizoSwap;
      do {
        hizoSwap = false;

        int puntajeSimulado = (equipoMenor['puntaje'] as int) + (suplente['calificacion'] as int);
        var equipoMasBajo = equiposVisuales.firstWhere((e) => e != equipoMenor);

        if ((puntajeSimulado - (equipoMasBajo['puntaje'] as int)) >= 2) {
          List<Map<String, dynamic>> posiblesSwap = List<Map<String, dynamic>>.from(equipoMenor['suplentes']);
          posiblesSwap.sort((a, b) => (a['calificacion'] as int).compareTo(b['calificacion'] as int));

          for (var swapJugador in posiblesSwap) {
            if ((swapJugador['calificacion'] as int) < (suplente['calificacion'] as int)) {
              equipoMenor['suplentes'].remove(swapJugador);
              equipoMasBajo['suplentes'].add(swapJugador);

              // Recalcular puntajes
              equipoMenor['puntaje'] =
                  _sumarCalificaciones([...equipoMenor['jugadores'], ...equipoMenor['suplentes']]);
              equipoMasBajo['puntaje'] =
                  _sumarCalificaciones([...equipoMasBajo['jugadores'], ...equipoMasBajo['suplentes']]);

              hizoSwap = true;
              break; // Solo un swap por iteración, pero se repite si aún es necesario
            }
          }
        }
      } while (hizoSwap);

      (equipoMenor['suplentes'] as List).add(suplente);
      equipoMenor['puntaje'] = _sumarCalificaciones([...equipoMenor['jugadores'], ...equipoMenor['suplentes']]);
    }

    setState(() {});
  }

  int _sumarCalificaciones(List<Map<String, dynamic>> jugadores) {
    return jugadores.fold(0, (sum, j) => sum + (j['calificacion'] as int));
  }

  // ---------------------- Modo eliminar jugadores ----------------------

  void _toggleDeleteMode([bool? value]) {
    setState(() {
      _deleteMode = value ?? !_deleteMode;
      if (!_deleteMode) _seleccionados.clear();
    });
  }

  // ---------------------- UI: Jugadores ----------------------

  PreferredSizeWidget _buildAppBarJugadores() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(180, 173, 216, 230),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ListTile(
              leading: IconButton(
                tooltip: 'Acerca del proyecto',
                icon: const Icon(Icons.help_outline, color: Colors.black87),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Center(child: Text('Instituto Superior Goya')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Image.network(
                            'https://isgoya-crr.infd.edu.ar/sitio/wp-content/uploads/2018/08/isglogo.jpg',
                            height: 200,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Proyecto de Prácticas Profesionalizantes\n'
                                'Tecnicatura Superior en Desarrollo de Software - 2do Año\n\n'
                                'Participantes:\n'
                                '• Daniel Balcedo\n'
                                '• Facundo Moreira\n'
                                '• Leo Meza\n'
                                '• Enzo Mondaque\n\n'
                                '🚫 Prohibida su distribución',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      actions: [
                        Center(
                          child: TextButton(
                            child: const Text('Aceptar'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
              title: const Text(
                'Newcom - Lista de Jugadores',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (_deleteMode)
                    IconButton(
                      tooltip: 'Confirmar',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.black87),
                      ),
                      onPressed: _eliminarSeleccionados,
                    ),
                  IconButton(
                    tooltip: _deleteMode ? 'Cancelar selección' : 'Eliminar',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _deleteMode ? Icons.close : Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                    onPressed: _toggleDeleteMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJugadoresPage() {

    return Scaffold(
      appBar: _buildAppBarJugadores(),
      body: jugadores.isEmpty
          ? const Center(child: Text('No hay jugadores registrados'))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: jugadores.length,
        itemBuilder: (context, index) {
          final jugador = jugadores[index];
          final colorFondo = jugador['genero'] == 'Hombre'
              ? Colors.blue.withOpacity(0.6)
              : Colors.pink.withOpacity(0.6);
          final seleccionado = _seleccionados.contains(index);

          return Card(
            color: colorFondo,
            shape: RoundedRectangleBorder(
              side: seleccionado
                  ? const BorderSide(width: 2)
                  : BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: _deleteMode
                  ? () {
                setState(() {
                  if (_seleccionados.contains(index)) {
                    _seleccionados.remove(index);
                  } else {
                    _seleccionados.add(index);
                  }
                });
              }
                  : null,
              leading: _deleteMode
                  ? Checkbox(
                value: _seleccionados.contains(index),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _seleccionados.add(index);
                    } else {
                      _seleccionados.remove(index);
                    }
                  });
                },
              )
                  : const Icon(Icons.person, size: 40),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    jugador['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${jugador['edad']} años'),
                ],
              ),
              subtitle: Row(
                children: [
                  Row(
                    children: List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < (jugador['calificacion'] ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${jugador['rol']})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        onPressed: _agregarJugador,
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }

  // ---------------------- Constructs ----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildJugadoresPage(),
          _InicioPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Jugadores'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ---------------------- Inicio ----------------------

  Widget _InicioPage() {
    // Contar varones y mujeres
    final cantidadVarones = jugadores
        .where((j) => j['genero'] == 'Hombre')
        .length;
    final cantidadMujeres = jugadores
        .where((j) => j['genero'] == 'Mujer')
        .length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            // Parte superior: cantidad total y varones/mujeres
            Column(
              children: [
                Text(
                  'Cantidad de jugadores: ${jugadores.length}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Varones: $cantidadVarones',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    Text(
                      'Mujeres: $cantidadMujeres',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink),
                    ),
                  ],
                ),
              ],
            ),

            //carta para los equipos
            Expanded(
              child: equiposVisuales.isEmpty
                  ? Center(child: Text('No hay equipos generados aún'))
                  : LayoutBuilder(
                builder: (_, constraints) {
                  // Calcular ancho de cada card para que entren al menos 2 por fila con espacio
                  double cardWidth = (constraints.maxWidth - 12) / 2; // 12 = spacing
                  cardWidth = cardWidth > 280 ? 280 : cardWidth;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: equiposVisuales.map((equipo) {
                        List jugadores = equipo['jugadores'];
                        List suplentes = equipo['suplentes'];

                        Widget buildJugadorIcono(Map<String, dynamic> jugador, {double iconSize = 26}) {
                          Color colorGenero = jugador['genero'] == 'Mujer' ? Colors.pink : Colors.blue;
                          IconData iconRol = jugador['rol'] == 'Atacante' ? Icons.sports_martial_arts : Icons.shield;
                          int calif = jugador['calificacion'];

                          // Construir estrellas más pequeñas
                          List<Widget> estrellas = List.generate(5, (i) {
                            return Icon(
                              i < calif ? Icons.star : Icons.star_border,
                              size: 10, // más pequeño
                              color: Colors.amber,
                            );
                          });

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: estrellas),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person, size: iconSize, color: colorGenero),
                                  SizedBox(width: 2),
                                  Icon(iconRol, size: 16, color: Colors.white60),
                                ],
                              ),
                              SizedBox(height: 2),
                              SizedBox(
                                width: iconSize * 1.5,
                                child: Text(
                                  jugador['nombre'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Container(
                          width: cardWidth - 10,
                          // Fijamos altura para que todas igual, ajusta según contenido
                          height: 420,
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header equipo + puntaje
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      equipo['equipo'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${equipo['puntaje']} pts',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),

                              // Jugadores titulares: grid 2x3
                              Expanded(
                                flex: 3,
                                child: GridView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: jugadores.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.7,
                                  ),
                                  itemBuilder: (_, index) {
                                    return buildJugadorIcono(jugadores[index], iconSize: 26);
                                  },
                                ),
                              ),

                              SizedBox(height: 10),

                              // Sección suplentes con altura fija, siempre presente
                              Container(
                                height: 200,
                                child: // Sección suplentes con altura autoajustada en grid
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Suplentes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    suplentes.isNotEmpty
                                        ? GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: suplentes.length,
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3, // 👉 filas de 3
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 0.7,
                                      ),
                                      itemBuilder: (_, index) {
                                        return buildJugadorIcono(suplentes[index], iconSize: 24);
                                      },
                                    )
                                        : Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Center(
                                        child: Text(
                                          'Sin suplentes',
                                          style: TextStyle(
                                            color: Colors.white30,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )

                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

            // Parte inferior: botones
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      selectPlayers();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Iniciar sorteo',
                      style: TextStyle(fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          List<Map<String, dynamic>> listaParaSeleccion = [];
                          List<Map<String, dynamic>> suplentes = [];

                          for (var equipo in equiposVisuales) {
                            suplentes.addAll(equipo['suplentes']);
                          }


                          for (var equipo in equiposVisuales) {
                            // Jugadores titulares
                            for (var j in equipo['jugadores']) {
                              listaParaSeleccion.add({
                                ...j,
                                'equipo': equipo,     // Referencia al equipo
                                'esSuplente': false,  // Es titular
                              });
                            }

                            // Suplentes
                            for (var s in equipo['suplentes']) {
                              listaParaSeleccion.add({
                                ...s,
                                'equipo': equipo,
                                'esSuplente': true,   // Es suplente
                              });
                            }
                          }

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Seleccionar Jugador o Suplente'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    children: listaParaSeleccion.map<Widget>((jugadorMap) {
                                      IconData iconGenero = jugadorMap['genero'] == 'Hombre'
                                          ? Icons.person
                                          : Icons.person_outline;
                                      Color colorGenero = jugadorMap['genero'] == 'Hombre'
                                          ? Colors.blue
                                          : Colors.pink;
                                      IconData iconRol = jugadorMap['rol'] == 'Atacante'
                                          ? Icons.sports_martial_arts
                                          : Icons.shield;

                                      return ListTile(
                                        leading: Icon(iconGenero, color: colorGenero),
                                        title: Text(jugadorMap['nombre']),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(iconRol),
                                            const SizedBox(width: 4),
                                            Row(
                                              children: List.generate(5, (i) {
                                                return Icon(
                                                  i < jugadorMap['calificacion']
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  size: 14,
                                                  color: Colors.amber,
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          _confirmarSustitucion(context, jugadorMap);
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Cancelar'),
                                  ),
                                ],
                              );
                            },
                          );

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          'Descontar jugador (-)',
                          style: TextStyle(color: Colors.red,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: agregarJugadorDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: const Text(
                          'Agregar jugador (+)',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- Funciones de sorteo y sustitucion ----------------------

  void _confirmarSustitucion(BuildContext context, Map<String, dynamic> jugadorSeleccionado) {
    List<Map<String, dynamic>> suplentes = jugadorSeleccionado['equipo']['suplentes']
        .where((s) => s['nombre'] != jugadorSeleccionado['nombre']) // evitar reemplazarse a sí mismo
        .toList();

    Map<String, dynamic>? reemplazo = encontrarReemplazo(jugadorSeleccionado, suplentes);

    if (reemplazo == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sin Reemplazo'),
          content: Text('No hay suplentes para cubrir la posición del jugador. ¿Desea resortear los equipos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                selectPlayers();
              },
              child: Text('Sí'),
            ),
            TextButton(
              onPressed: () {
                var equipo = jugadorSeleccionado['equipo'];

                // Buscar y eliminar al jugador ya sea en titulares o suplentes comparando nombres
                for (var lista in [equipo['jugadores'], equipo['suplentes']]) {
                  for (int i = 0; i < lista.length; i++) {
                    if (lista[i]['nombre'] == jugadorSeleccionado['nombre']) {
                      lista.removeAt(i);
                      break; // salir del for interno al encontrar el jugador
                    }
                  }
                }

                // Recalcular el puntaje del equipo
                int nuevoPuntaje = 0;
                for (var j in [...equipo['jugadores'], ...equipo['suplentes']]) {
                  nuevoPuntaje += j['calificacion'] as int;
                }
                equipo['puntaje'] = nuevoPuntaje;

                setState(() {}); // refrescar la UI
                Navigator.of(context).pop(); // cerrar el diálogo
                Navigator.of(context).pop(); // cerrar el diálogo
              },
              child: Text('No'),
            ),

          ],
        ),
      );
      return;
    }

    // Mostrar confirmación si hay reemplazo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmación'),
          content: Text(
            '¿Desea sacar a ${jugadorSeleccionado["nombre"]} del equipo? '
                'Este jugador será sustituido por ${reemplazo["nombre"]}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _realizarSustitucion(jugadorSeleccionado, reemplazo);
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _realizarSustitucion(Map<String, dynamic> jugadorSeleccionado, Map<String, dynamic> reemplazo) {
    var equipo = jugadorSeleccionado['equipo'];

    if (jugadorSeleccionado['esSuplente'] == true) {
      // Si es suplente, reemplazamos en la lista de suplentes
      equipo['suplentes'].remove(jugadorSeleccionado);
      equipo['suplentes'].add(reemplazo);
    } else {
      // Si es titular, reemplazamos en la lista de jugadores
      equipo['jugadores'].remove(jugadorSeleccionado);
      equipo['jugadores'].add(reemplazo);
    }

    // Actualizamos puntaje del equipo sumando todos los jugadores y suplentes
    int nuevoPuntaje = 0;
    for (var j in [...equipo['jugadores'], ...equipo['suplentes']]) {
      nuevoPuntaje += j['calificacion'] as int;
    }
    equipo['puntaje'] = nuevoPuntaje;

    setState(() {});
  }

  Map<String, dynamic>? encontrarReemplazo(Map<String, dynamic> jugadorSeleccionado, List<Map<String, dynamic>> suplentes) {
    var equipo = jugadorSeleccionado['equipo'];

    // Excluir al jugador seleccionado y suplentes que ya estén en su equipo
    final posibles = suplentes.where((s) =>
    s['nombre'] != jugadorSeleccionado['nombre'] &&
        !(equipo['suplentes'] as List).any((e) => e['nombre'] == s['nombre'])
    ).toList();

    // Buscar un suplente con calificación igual o mayor que el jugador seleccionado
    final candidatosBuenos = posibles.where(
            (s) => s['rol'] == jugadorSeleccionado['rol'] &&
            s['calificacion'] >= jugadorSeleccionado['calificacion']
    ).toList();

    if (candidatosBuenos.isNotEmpty) {
      candidatosBuenos.sort((a, b) => a['calificacion'].compareTo(b['calificacion']));
      return candidatosBuenos.first;
    }

    // Si no hay candidatos “buenos”, buscar los más flojos pero del mismo rol
    final candidatosMenores = posibles.where(
            (s) => s['rol'] == jugadorSeleccionado['rol']
    ).toList();

    if (candidatosMenores.isEmpty) return null;

    // Elegir el que tenga la diferencia más pequeña
    candidatosMenores.sort((a, b) =>
        (b['calificacion'] - jugadorSeleccionado['calificacion']).abs()
            .compareTo((a['calificacion'] - jugadorSeleccionado['calificacion']).abs()));

    final mejorOpcion = candidatosMenores.first;
    final diferencia = (jugadorSeleccionado['calificacion'] - mejorOpcion['calificacion']).abs();

    if (diferencia >= 2) {
      return {'_necesitaResortear': true};
    }

    return mejorOpcion;
  }

  void selectPlayers() {
    final Set<int> seleccionadosDialog = {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Seleccionar jugadores para sorteo'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: jugadores.length,
                  itemBuilder: (context, index) {
                    final jugador = jugadores[index];
                    return ListTile(
                      onTap: () {
                        setStateDialog(() {
                          if (seleccionadosDialog.contains(index)) {
                            seleccionadosDialog.remove(index);
                          } else {
                            seleccionadosDialog.add(index);
                          }
                        });
                      },
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: seleccionadosDialog.contains(index),
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value == true) {
                                  seleccionadosDialog.add(index);
                                } else {
                                  seleccionadosDialog.remove(index);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: jugador['genero'] == 'Mujer' ? Colors.pink : Colors.blue,
                            child: Icon(
                              jugador['genero'] == 'Mujer' ? Icons.female : Icons.male,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            jugador['nombre'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${jugador['edad']} años'),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < (jugador['calificacion'] ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${jugador['rol']})',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Llamamos a la función de iniciar sorteo pasando los seleccionados
                    final List<Map<String, dynamic>> jugadoresSeleccionados =
                    seleccionadosDialog.map((i) => jugadores[i]).toList();

                    startSort(jugadoresSeleccionados);

                    Navigator.pop(context);
                  },
                  child: const Text('Iniciar sorteo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void startSort(List<Map<String, dynamic>> jugadoresSeleccionados) {
    equiposVisuales.clear();

    if (jugadoresSeleccionados.isEmpty) return;

    // Separar por género
    List<Map<String, dynamic>> hombres = jugadoresSeleccionados.where((j) => j['genero'] == 'Hombre').toList();
    List<Map<String, dynamic>> mujeres = jugadoresSeleccionados.where((j) => j['genero'] == 'Mujer').toList();

    int totalJugadores = jugadoresSeleccionados.length;
    int nEquipos = (totalJugadores / 6).floor();
    if (nEquipos < 1) nEquipos = 1;

    // Determinar género minoritario
    List<Map<String, dynamic>> minGenero = hombres.length < mujeres.length ? hombres : mujeres;
    String generoMin = hombres.length < mujeres.length ? 'Hombre' : 'Mujer';

    int generoPorEquipo = (minGenero.length / nEquipos).floor();

    // Separar minoría por rol
    List<Map<String, dynamic>> minorAtacantes = minGenero.where((j) => j['rol'] == 'Atacante').toList();
    List<Map<String, dynamic>> minorDefensores = minGenero.where((j) => j['rol'] == 'Defensor').toList();

    // Crear estructuras iniciales
    List<List<Map<String, dynamic>>> equipos = List.generate(nEquipos, (_) => []);
    List<int> sumasEquipos = List.filled(nEquipos, 0);
    List<Map<String, int>> contadorRoles = List.generate(nEquipos, (_) => {'Atacante': 0, 'Defensor': 0});

    // Función para asignar un jugador al equipo más balanceado
    void asignarPorRol(List<Map<String, dynamic>> jugadores, String rol) {
      jugadores.sort((a, b) => b['calificacion'].compareTo(a['calificacion']));
      for (var jugador in jugadores) {
        int? mejorEquipo;
        int? menorCalif;

        for (int i = 0; i < nEquipos; i++) {
          if (contadorRoles[i][rol]! < generoPorEquipo) {
            int suma = sumasEquipos[i];
            if (mejorEquipo == null || suma < menorCalif!) {
              mejorEquipo = i;
              menorCalif = suma;
            }
          }
        }

        if (mejorEquipo != null) {
          equipos[mejorEquipo].add(jugador);
          sumasEquipos[mejorEquipo] += (jugador['calificacion'] as int);
          contadorRoles[mejorEquipo][rol] = contadorRoles[mejorEquipo][rol]! + 1;
        }
      }
    }

    // 1. Asignar minoría por rol equilibradamente
    asignarPorRol(minorAtacantes, 'Atacante');
    asignarPorRol(minorDefensores, 'Defensor');

    // 2. Asignar el resto de jugadores hasta 6 titulares por equipo
    List<Map<String, dynamic>> asignados = equipos.expand((e) => e).toList();
    List<Map<String, dynamic>> resto = jugadoresSeleccionados.where((j) => !asignados.contains(j)).toList();

    resto.sort((a, b) => b['calificacion'].compareTo(a['calificacion']));

    for (var jugador in resto) {
      int? mejorEquipo;
      int? menorCalif;

      for (int i = 0; i < nEquipos; i++) {
        if (equipos[i].length < 6) {
          int suma = sumasEquipos[i];
          if (mejorEquipo == null || suma < menorCalif!) {
            mejorEquipo = i;
            menorCalif = suma;
          }
        }
      }

      if (mejorEquipo != null) {
        equipos[mejorEquipo].add(jugador);
        sumasEquipos[mejorEquipo] += (jugador['calificacion'] as int);
        contadorRoles[mejorEquipo][jugador['rol']] = contadorRoles[mejorEquipo][jugador['rol']]! + 1;
      }
    }

    // 2.5: Optimización de roles después de asignar titulares
      for (int i = 0; i < equipos.length; i++) {
        for (int j = i + 1; j < equipos.length; j++) {
          for (int a = 0; a < equipos[i].length; a++) {
            for (int b = 0; b < equipos[j].length; b++) {
              var jugadorA = equipos[i][a];
              var jugadorB = equipos[j][b];

              int califA = jugadorA['calificacion'] as int;
              int califB = jugadorB['calificacion'] as int;

              if ((califA - califB).abs() <= 1 && jugadorA['rol'] != jugadorB['rol']) {
                int nuevosDefI = equipos[i].where((j) => (j == jugadorA ? jugadorB : j)['rol'] == 'Defensor').length;
                int nuevosDefJ = equipos[j].where((j) => (j == jugadorB ? jugadorA : j)['rol'] == 'Defensor').length;

                int actualesDefI = equipos[i].where((j) => j['rol'] == 'Defensor').length;
                int actualesDefJ = equipos[j].where((j) => j['rol'] == 'Defensor').length;

                int diffActual = (actualesDefI - actualesDefJ).abs();
                int diffNueva = (nuevosDefI - nuevosDefJ).abs();

                if (diffNueva < diffActual) {
                  equipos[i][a] = jugadorB;
                  equipos[j][b] = jugadorA;
                }
              }
            }
          }
        }
      }

      //2.6 requilibrar generos y roles (misma cantidad de roles por genero si es posible)
    for (int i = 0; i < equipos.length; i++) {
      for (int j = i + 1; j < equipos.length; j++) {
        for (int a = 0; a < equipos[i].length; a++) {
          for (int b = 0; b < equipos[j].length; b++) {
            var jugadorA = equipos[i][a];
            var jugadorB = equipos[j][b];

            // Mismo género pero roles diferentes
            if (jugadorA['genero'] == jugadorB['genero'] && jugadorA['rol'] != jugadorB['rol']) {
              int califA = jugadorA['calificacion'] as int;
              int califB = jugadorB['calificacion'] as int;

              if ((califA - califB).abs() <= 1) {
                // Ahora buscamos el segundo intercambio para el otro género
                String generoComplementario = jugadorA['genero'] == 'Hombre' ? 'Mujer' : 'Hombre';

                bool intercambioRealizado = false;

                outerLoop:
                for (int c = 0; c < equipos[i].length; c++) {
                  for (int d = 0; d < equipos[j].length; d++) {
                    var jugadorC = equipos[i][c];
                    var jugadorD = equipos[j][d];

                    // Que sean del género complementario y roles opuestos también
                    if (jugadorC['genero'] == generoComplementario && jugadorD['genero'] == generoComplementario &&
                        jugadorC['rol'] != jugadorD['rol']) {
                      int califC = jugadorC['calificacion'] as int;
                      int califD = jugadorD['calificacion'] as int;

                      if ((califC - califD).abs() <= 1) {
                        // Simulamos el efecto de ambos intercambios en los roles
                        // Contamos roles antes y después para ambos géneros en ambos equipos

                        // Para género de jugadorA (primer intercambio)
                        int rolCountIAnt = equipos[i].where((j) => j['genero'] == jugadorA['genero'] && j['rol'] == 'Atacante').length;
                        int rolCountIDef = equipos[i].where((j) => j['genero'] == jugadorA['genero'] && j['rol'] == 'Defensor').length;
                        int rolCountJAnt = equipos[j].where((j) => j['genero'] == jugadorB['genero'] && j['rol'] == 'Atacante').length;
                        int rolCountJDef = equipos[j].where((j) => j['genero'] == jugadorB['genero'] && j['rol'] == 'Defensor').length;

                        // Aplicar primer intercambio
                        if (jugadorA['rol'] == 'Atacante' && jugadorB['rol'] == 'Defensor') {
                          rolCountIAnt--;
                          rolCountIDef++;
                          rolCountJAnt++;
                          rolCountJDef--;
                        } else {
                          rolCountIAnt++;
                          rolCountIDef--;
                          rolCountJAnt--;
                          rolCountJDef++;
                        }

                        // Para género complementario (segundo intercambio)
                        int rolCountICompAnt = equipos[i].where((j) => j['genero'] == generoComplementario && j['rol'] == 'Atacante').length;
                        int rolCountICompDef = equipos[i].where((j) => j['genero'] == generoComplementario && j['rol'] == 'Defensor').length;
                        int rolCountJCompAnt = equipos[j].where((j) => j['genero'] == generoComplementario && j['rol'] == 'Atacante').length;
                        int rolCountJCompDef = equipos[j].where((j) => j['genero'] == generoComplementario && j['rol'] == 'Defensor').length;

                        // Aplicar segundo intercambio
                        if (jugadorC['rol'] == 'Atacante' && jugadorD['rol'] == 'Defensor') {
                          rolCountICompAnt--;
                          rolCountICompDef++;
                          rolCountJCompAnt++;
                          rolCountJCompDef--;
                        } else {
                          rolCountICompAnt++;
                          rolCountICompDef--;
                          rolCountJCompAnt--;
                          rolCountJCompDef++;
                        }

                        // Evaluar si mejora la simetría en ambos géneros (suma de diferencias antes y después)
                        int diffAntes =
                            (equipos[i].where((j) => j['genero'] == jugadorA['genero'] && j['rol'] == 'Atacante').length - equipos[i].where((j) => j['genero'] == jugadorA['genero'] && j['rol'] == 'Defensor').length).abs() +
                                (equipos[j].where((j) => j['genero'] == jugadorB['genero'] && j['rol'] == 'Atacante').length - equipos[j].where((j) => j['genero'] == jugadorB['genero'] && j['rol'] == 'Defensor').length).abs() +
                                (equipos[i].where((j) => j['genero'] == generoComplementario && j['rol'] == 'Atacante').length - equipos[i].where((j) => j['genero'] == generoComplementario && j['rol'] == 'Defensor').length).abs() +
                                (equipos[j].where((j) => j['genero'] == generoComplementario && j['rol'] == 'Atacante').length - equipos[j].where((j) => j['genero'] == generoComplementario && j['rol'] == 'Defensor').length).abs();

                        int diffDespues =
                            (rolCountIAnt - rolCountIDef).abs() +
                                (rolCountJAnt - rolCountJDef).abs() +
                                (rolCountICompAnt - rolCountICompDef).abs() +
                                (rolCountJCompAnt - rolCountJCompDef).abs();

                        if (diffDespues < diffAntes) {
                          // Realizar ambos intercambios
                          equipos[i][a] = jugadorB;
                          equipos[j][b] = jugadorA;
                          equipos[i][c] = jugadorD;
                          equipos[j][d] = jugadorC;
                          intercambioRealizado = true;
                          break outerLoop;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

      // 3. Asignar suplentes al equipo con menos del rol o menor puntaje (reevaluando después de cada asignación)
    List<Map<String, dynamic>> titularesFinales = equipos.expand((e) => e).toList();
    List<Map<String, dynamic>> suplentes = jugadoresSeleccionados.where((j) => !titularesFinales.contains(j)).toList();

    for (var suplente in suplentes) {
      String rol = suplente['rol'];
      int? equipoIdeal;
      int menorValor = 999999;

      // Recalcular el mejor equipo en cada iteración
      for (int i = 0; i < nEquipos; i++) {
        int rolCount = equipos[i].where((j) => j['rol'] == rol).length;
        int total = equipos[i].fold(0, (sum, j) => sum + (j['calificacion'] as int));

        int valor = rolCount * 100 + total; // prioridad a menor cantidad del rol + menor puntaje total
        if (valor < menorValor) {
          menorValor = valor;
          equipoIdeal = i;
        }
      }

      if (equipoIdeal != null) {
        equipos[equipoIdeal].add(suplente);
        sumasEquipos[equipoIdeal] += suplente['calificacion'] as int;
      }
    }


    // 4. equilibrar género y roles
    if (nEquipos == 2) {
      String generoMayor = generoMin == 'Hombre' ? 'Mujer' : 'Hombre';

      List<int> countGeneroMin = equipos.map((e) =>
      e.where((j) => j['genero'] == generoMin).length
      ).toList();

      int totalMin = countGeneroMin.reduce((a, b) => a + b);
      int diferencia = (countGeneroMin[0] - countGeneroMin[1]).abs();

      if ((totalMin.isEven && diferencia != 0) || (totalMin.isOdd && diferencia > 1)) {
        int mayorIdx = countGeneroMin[0] > countGeneroMin[1] ? 0 : 1;
        int menorIdx = 1 - mayorIdx;

        // Buscar jugador del género minoritario en el equipo con más
        for (var jugadorMin in equipos[mayorIdx]) {
          if (jugadorMin['genero'] != generoMin) continue;

          for (var jugadorMayor in equipos[menorIdx]) {
            if (jugadorMayor['genero'] != generoMayor) continue;
            if (jugadorMayor['rol'] != jugadorMin['rol']) continue;

            int califMin = jugadorMin['calificacion'] as int;
            int califMayor = jugadorMayor['calificacion'] as int;

            if ((califMin - califMayor).abs() <= 1) {
              equipos[mayorIdx].remove(jugadorMin);
              equipos[menorIdx].remove(jugadorMayor);

              equipos[mayorIdx].add(jugadorMayor);
              equipos[menorIdx].add(jugadorMin);

              break;
            }
          }

          // detener si ya se hizo el intercambio
          if ((equipos[mayorIdx].where((j) => j['genero'] == generoMin).length -
              equipos[menorIdx].where((j) => j['genero'] == generoMin).length).abs() <= 1) {
            break;
          }
        }
      }
    }

    // Paso 5: Mejorar balance de puntajes con intercambios de jugadores mismo rol y género
    for (int i = 0; i < equipos.length; i++) {
      for (int j = i + 1; j < equipos.length; j++) {
        for (int a = 0; a < equipos[i].length; a++) {
          for (int b = 0; b < equipos[j].length; b++) {
            var jugadorA = equipos[i][a];
            var jugadorB = equipos[j][b];

            // Solo si tienen el mismo rol y mismo género
            if (jugadorA['rol'] == jugadorB['rol'] && jugadorA['genero'] == jugadorB['genero']) {
              int califA = jugadorA['calificacion'] as int;
              int califB = jugadorB['calificacion'] as int;

              // Diferencia de calificación debe ser mayor para hacer intercambio útil (por ej. 2 o más)
              if ((califA - califB).abs() >= 2) {
                // Calculamos diferencia total de puntajes antes y después del intercambio
                int sumaA = equipos[i].fold(0, (sum, j) => sum + (j['calificacion'] as int));
                int sumaB = equipos[j].fold(0, (sum, j) => sum + (j['calificacion'] as int));

                int diffAntes = (sumaA - sumaB).abs();

                // Simulamos intercambio
                int sumaApost = sumaA - califA + califB;
                int sumaBpost = sumaB - califB + califA;

                int diffDespues = (sumaApost - sumaBpost).abs();

                // Solo hacemos intercambio si mejora el balance (reduce la diferencia)
                if (diffDespues < diffAntes) {
                  equipos[i][a] = jugadorB;
                  equipos[j][b] = jugadorA;
                  // Actualizamos sumas para seguir evaluando correctamente
                  // (podés actualizar sumasEquipos si los usás en otros lados)
                  break;
                }
              }
            }
          }
        }
      }
    }


    // 6. Crear estructura visual final
    for (int i = 0; i < equipos.length; i++) {
      List<Map<String, dynamic>> equipo = equipos[i];
      int totalCalif = equipo.fold(0, (prev, j) => prev + (j['calificacion'] as int));

      List<Map<String, dynamic>> titulares = equipo.length > 6 ? equipo.sublist(0, 6) : equipo;
      List<Map<String, dynamic>> suples = equipo.length > 6 ? equipo.sublist(6) : [];

      equiposVisuales.add({
        'equipo': 'Equipo ${i + 1}',
        'puntaje': totalCalif,
        'jugadores': titulares,
        'suplentes': suples,
      });
    }

    //Actualizamos la UI
    setState(() {});
  }
}