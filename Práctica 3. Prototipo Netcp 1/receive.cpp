#include "socket.hpp"
#include <system_error>

int main(void){
  try {
    // Les asignamos una ip a cada una llamando a la funcion creada "make_ip_adress"
    sockaddr_in local_address = make_ip_address("127.0.0.1", 8080); // 0
    sockaddr_in dest_address = make_ip_address("127.0.0.1", 8081);  // 1

    Socket socket(local_address);
    Message message;
    message.text[1023] = '\0';

    //LLamamos a la clase receive_from y le pasamos por parametros el mensaje y la direccion de destino
    socket.receive_from(message,dest_address);

    // Vamos a mostrar el mensaje recibido en la terminal
    // Primero convertimos la dirección IP como entero de 32 bits en una cadena de texto.
    char* remote_ip = inet_ntoa(dest_address.sin_addr);
    // Recuperamos el puerto del remitente en el orden adecuado para nuestra CPU
    int remote_port = ntohs(dest_address.sin_port);

    // Imprimimos el mensaje y la dirección del remitente
    std::cout << "El sistema " << remote_ip << ":" << remote_port << " envió el mensaje '" << message.text.data() << "'" << std::endl;

  }
  
  //Intentamos localizar excepciones
	catch(std::bad_alloc& e) {
		std::cerr << "mytalk" << ": memoria insuficiente\n";
		return 1;
	}
	catch(std::system_error& e) {
		std::cerr << "mytalk" << ": " << e.what() << '\n';
		return 2;
	}
	catch (...) {
		std::cout << "Error desconocido\n";
	}
	return 0;	//Finalizamos el programa correctamente con un return 0

}