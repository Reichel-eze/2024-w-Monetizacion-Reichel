// ---------------------------------------------
// CONTENIDOS
// ---------------------------------------------

class Contenido {
  const property titulo
  var property cantidadDeVistas = 0           // la inicializo en 0, para despues modificarla
  var property esContenidoOfensivo = false    // la inicalizo como false (que no es ofensivo)  ---> "marcada como “contenido ofensivo” por su autor (o debido al pedido de otros usuarios)"

  // "El usuario puede cambiar en cualquier momento la forma de monetizar cada uno de sus contenidos, pero sólo puede aplicar una a cada uno."
  var monetizacion                   // seria la forma/estrategia de monetizacion, la forma en que el contenido se cotiza (cada contenido tiene una monetizacion)

  method monetizacion(nuevaMonetizacion) {          // mi propio setter de monetizacion ("valido en el propia setter") ("es decir siempre que se settee la monetizacion, primero verifico que pueda monetizar mi contenido con dicha monetizacion")
    if(!nuevaMonetizacion.puedeMonetizarse(self)){
      throw new DomainException(message="Este contenido NO soporta la forma de monetizacion")   // Si NO se puede aplicar la monetizacion (!), entonces tenemos una excepcion
    }
    monetizacion = nuevaMonetizacion                // si pasa la excepcion, se asigna correctamente la monetizacion ("puede monetizarse")
  }

  override method initialize(){      // para la instanciacion  
    if(!monetizacion.puedeMonetizarse(self)){
      throw new DomainException(message="Este contenido NO soporta la forma de monetizacion")
    }
  }

  method esPopular()                          // metodo abstracto ()"todo contenido tiene que entender este mensaje") (cada subclase lo desarolla)
  method recaudacionMaxima()                  // metodo abstracto (cada subclase lo desarrolla)                   

  method recaudacion() = monetizacion.recaudacionDe(self) // la recaudacion del contendio depende de su forma de monetizacion 

  method puedeAlquilarse()                    // metodo abstracto (cada subclase lo desarrolla)
       
  // method puedeMonetizarse() = monetizacion.puedeMonetizarse()

}

class Video inherits Contenido {
  override method esPopular() = cantidadDeVistas > 10000 
  override method recaudacionMaxima() = 10000

  override method puedeAlquilarse() = true // porque es un video
}

// La lista de tags de moda!!
const tagsDeModa = ["objetos","pdep","serPeladoHoy"]

class Imagen inherits Contenido {
  const property tags = [] 
  
  override method esPopular() = tagsDeModa.all({tag => tags.contains(tag)})  // una imagen es popular si está marcada con todos los tags de moda (una lista de tags arbitrarios que actualizamos a mano y puede cambiar en cualquier momento).
                                                                             // "para cada uno de los tags de Moda, yo espero que se encuentren dentro de mis tags"
  override method recaudacionMaxima() = 4000 

  override method puedeAlquilarse() = false // porque NO es un video
}

// ---------------------------------------------
// ESTRATEGIAS DE MONETIZACION
// ---------------------------------------------

object publicidad {   // es un objeto porque cualquier publicidad va a tener el mismo metodo de recaudacion (porque NO necesito manipular ningun estado interno)

  // 1ero) El usuario cobra 5 centavos por cada vista que haya tenido su contenido.
  // 2dos) Además los contenidos populares cobran un plus de $2000, sino no, no cobran ese plus (cada tipo tiene su forma de ser popular)
  // 3ero) Ninguna publicación puede recaudar con publicidades más de cierto máximo que depende del tipo (video o imagenes) (incluyendo el plus).

  method recaudacionDe(contenido) = (
    0.05 * contenido.cantidadDeVistas() + 
    if(contenido.esPopular()) 2000 else 0     
    ).min(contenido.recaudacionMaxima())

  // Sólo las publicaciones no-ofensivas pueden monetizarse por publicidad
  method puedeMonetizarse(contenido) = contenido.esContenidoOfensivo().not() // o !contenido.esContenidoOfensivo()


}

class Donacion {        // lo hago una class porque puede haber muchas donaciones y cada una tiene su monto (manipulo un estado interno para cada donacion)
  var property montoDonaciones = 0

  method recaudacionDe(contenido) = montoDonaciones 

  method puedeMonetizarse(contenido) = true   // Todos los contenidos pueden ser monetizados por donaciones
}

class VentaDeDescarga { // lo hago una class porque cada ventadeDescarga va a tener un precioFijo
  const property precioFijo

  method recaudacionDe(contenido) = precioFijo * contenido.cantidadDeVistas() 
  //method recaudacionDe(contenido) = 5.max(precioFijo) * contenido.cantidadDeVistas()    // El valor mínimo de venta es de $5.00 y se cobra por cada vista.

  method puedeMonetizarse(contenido) = contenido.esPopular()
}

// 4) Aparece un nuevo tipo de estrategia de monetizacion: El Alquiler

class Alquiler inherits VentaDeDescarga {

  override method precioFijo() = 1.max(super()) // El valor mínimo de venta es de $1.00 
    
  override method puedeMonetizarse(contenido) = super(contenido) and contenido.puedeAlquilarse()    // el puedeAlquilarse seria un esVideo() pero el nombre "puede alquilarse" es mas descriptivo/concreto teniendo en cuenta en un futuro si aparecen otros formartos que puedan alquilarse y no soy videos

}

// ---------------------------------------------
// USUARIOS
// ---------------------------------------------

class Usuario {
  const property nombre
  const property email
  var property verificado = false   // en un comienzo a los usuarios se los considera "sin verificar" 
  const property contenidos = []    // tiene contenidos

  method saldoTotal() = contenidos.sum({contenido => contenido.recaudacion()})

  method esSuperUsuario() = contenidos.filter({contenido => contenido.esPopular()}).size() >= 10    // usuarios que tienen al menos 10 contenidos populares publicados).
                      // o  contenidos.count({contenido => contenido.esPopular()}) >= 10

  // 3) Permitir que un usuario publique un nuevo contenido, asociandolo a una forma de monetizacion
  method publicarContenido(contenido) { 
      contenidos.add(contenido)   // si pudiste contruirlo, significa que es consistente (porque toda la logica de consistencia la hice en el setter, y en el initialize)
    
  }
}

object plataforma {                 // (objeto compañero) para conductas que no dependan de un objeto en particular, se refieren al todo
  const property todosLosUsuarios = [] 

  // 2.b) Email de los 100 usuarios verificados con mayor saldo total.
  method emailsUsuarioVerificadosRicos() = todosLosUsuarios
    .filter({usuario => usuario.verificado()})
    .sortBy({uno, otro => uno.saldoTotal() > otro.saldoTotal()})
    .take(100)
    .map({usuario => usuario.email()})
    
    // Bien
    // 1ero filtro los usuarios verificados
    // 2dos los ordeno segun el saldo total
    // 3ero tomo los primeros 100 usuarios mas ricos
    // 4tos transformo la lista de 100 en una lista de 100 emails
    
    // Mal
    //todosLosUsuarios.map({usuario => usuario.verificado()})
    //.map(x => x.email())
    //.sortBy({uno, otro => uno.saldoTotal() > otro.saldoTotal()})
    //.take(100) 

    method cantidadDeSuperUsuarios() = todosLosUsuarios.filter({usuario => usuario.esSuperUsuario()}).size() 
                                // o = todosLosUsarios.count({usuario => usuario.esSuperUsuario()})
}

// PUNTO 5 
// Responder sin implementar:

// a. ¿Cuáles de los siguientes requerimientos te parece que sería el más fácil y 
// cuál el más difícil de implementar en la solución que modelaste? Responder relacionando cada caso con conceptos del paradigma.
// i. Agregar un nuevo tipo de contenido.
// ii. Permitir cambiar el tipo de un contenido (e.j.: convertir un video a imagen).
// iii. Agregar un nuevo estado “verificación fallida” a los usuarios, que no les permita cargar ningún nuevo contenido.

// i. Agregar un nuevo tipo de contenido no seria para nada dificil, heredaria todos los atributos y metodos de la clase base Contenido, 
// solo que simplemente deberia tener en cuenta aquellos metodos abstractos que son comunes a todos los contenidos 
// y su desarrollo/implementacion que tendra en este nuevo tipo de contenido

// ii. Si permito cambiar el tipo de un contenido, los tipos de contenidos ya NO podrian ser mas clases que heredad de la clase base
// Si queremos hacer eso, podriamos hjacer una varible que se llama tipo por ej, y a ese atributo le delego las cosas del tipo de contenido


// ¿En qué parte de tu solución se está aprovechando más el uso de polimorfismo? ¿Por qué?

// Polimorfimo NO es lo mismo que Herencia
// Polimorfismo = trato indistinto de uno o mas objetos por un tercero 

// En este codigo, se utiliza el polimorfismi:
// - saldoTotal() en Usuario, porque no distingue el tipo de contenido en ese momento
// - recaudacion() en Contenido, porque no distingue caules es la monetizacion que tiene 
