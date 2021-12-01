#include "socket.hpp"

sockaddr_in make_ip_address(const std::string& ip_address, int port){
  sockaddr_in address{}; //Inicalizando a 0
  address.sin_family = AF_INET; //Pues el socket es de dominio AF_INET
  
  //Si la dirección IP en ip_address es una cadena vacía "", la dirección IP almacenada en sockaddr_in deberá ser INADDR_ANY.
  if ( ip_address == "") {
    address.sin_addr.s_addr = htonl(INADDR_ANY); //htons convierte enteros de 32 bits como una dirección ip en entero de 16 bits como los números de puerto
  } else {
    inet_aton(ip_address.data(), &address.sin_addr);
  }
  address.sin_port = htons(port);

  return address;
}

Socket::Socket(sockaddr_in& local_address){

    fd_ = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd_ < 0) {
      //Si el socket no se crea correctamente lanzamos un mensaje de error
      throw std::system_error(errno, std::system_category(), "no se pudo crear el socket");
      std::cerr << "Error en la descripcion del fichero" << std::strerror(errno) << "\n";
      return; 	// Error

      //return 3; //Error terminar con valor diferente y > 0.
    }
	
    //Vincular dicho socket a la dirección de Internet especificada mediante el argumento ‘address’ del constructor, utilizando la llamada al sistema bind().
    int result = bind(fd_, reinterpret_cast<const sockaddr*>(&local_address), sizeof(local_address));
    if (result < 0) {
      //Si el socket no se crea correctamente lanzamos un mensaje de error
      std::cerr << "Fallo en la direccion de internet, funcion bind()\n";
      return;		// Error

      //return 5;    // Error. Terminar con un valor diferente y > 0
    }
}

Socket::~Socket(){
  //Cerramos fd_ mediante la llamada close()
  close(fd_);
}

// Send_to
void Socket::send_to(const Message& message, const sockaddr_in& address){
  int result = sendto(fd_, &message, sizeof(message), 0, reinterpret_cast<const sockaddr*>(&address), sizeof(address));
    if (result < 0) {
      std::cerr << "Fallo en el send_to: " << std::strerror(errno) << '\n';
		  return;
    }
}

// Receive_from
void Socket::receive_from(Message& message, sockaddr_in& address){
  socklen_t len = sizeof(address);
  int result = recvfrom(fd_, &message, sizeof(message), 0,
      reinterpret_cast<sockaddr*>(&address), &len);
  if (result < 0) {
    std::cerr << "Fallo en la funcion de receive_from: " << std::strerror(errno) << '\n';
		return;
  }
}
