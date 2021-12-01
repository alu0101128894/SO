#include"socket.hpp"

std::atomic<bool> quit(false); // quit_app
std::set<std::pair<int, std::thread *>> active_threads;

//server socket
sockaddr_in local_address_s;
sockaddr_in dest_address_s;
//client socket
sockaddr_in local_address_c;
sockaddr_in dest_address_c;


Message message;

//funcion help. Muestra la ayuda
void help(void){
  std::cout << "./Netcp [-s] [-c] [-h] [-p]" << std::endl;
  std::cout << "-h " << "Mostrar la ayuda"<< std::endl;
  std::cout << "-s " << "Modo servidor"<< std::endl;
  std::cout << "-c " << "Modo cliente [ip]"<< std::endl;
  std::cout << "-p " << "Especificar puerto [port]"<< std::endl;
}

//Argumentos
struct CommandLineArguments{
    bool show_help = false;
    bool server_mode = false;
    bool client_mode = false;
    bool port_opcion = false;
    int conn_port = 0;
    std::string ip_client_dest;
    std::vector<std::string> other_arguments;

    CommandLineArguments(int argc, char* argv[]);
};

CommandLineArguments::CommandLineArguments(int argc, char* argv[])
{
  int c;
    while ( (c = getopt(argc, argv, "hsc:p:01")) != -1){
        // Recuerda que "c" contiene la letra de la opción.
      switch (c) {
          case '0':
          case '1':
                 std::cerr << "opción " << c << std::endl;
              break;
          case 'h':
          std::cerr << "opción h\n";              // AYUDA
                 show_help = true;
              break;
          case 's':
              std::cerr << "opción s\n";          // SERVER_MODE
                 server_mode = true;
              break;
          case 'p':
            // Esta opción recibe un argumento.
            // getopt() lo guarda en la variable global "optarg"
                std::cerr << "opción p con valor " << optarg << std::endl;        //CONN_PORT
                conn_port = std::atoi(optarg);
                port_opcion = true;
                break;
          case 'c':
                std::cerr << "opción c\n";    // IP_CLIENT_DEST
                 client_mode = true;
                 ip_client_dest = std::string(optarg);
                break;
          case '?':
          // c == '?' cuando la opción no está en la lista
          // getopt() se encarga de mostrar el mensaje de error.
              throw std::invalid_argument("Argumento de línea de comandos desconocido");  // ERROR ARGUMENTO
          default:
          // Si "c" vale cualquier otra cosa, algo fue mal con
          // getopt(). Esto no debería pasar nunca.
          throw std::runtime_error("Error procesando la línea de comandos");              // ERROR COMANDO
      }
    }

    if (optind < argc) {
             std::cerr << "-- empezamos con los argumentos no opción --\n";
        for (; optind < argc; ++optind) {
          std::cerr << "argv[" << optind << "]: " <<
          argv[optind] << '\n';
          other_arguments.push_back(argv[optind]);
        }
    }

}

//Función enviar para el hilo
void functionSend(Socket& socket, std::exception_ptr& eptr, std::string fichName){
    sigset_t set;
    sigaddset(&set, SIGINT);
    sigaddset(&set, SIGTERM);
    sigaddset(&set, SIGHUP);

    pthread_sigmask(SIG_BLOCK, &set, nullptr);

  try{
    std::cout << "despues: " << fichName << std::endl;
    int fe = open(fichName.c_str(), O_RDONLY);
    if(fe < 0){
      std::cerr << "No se pudo abrir el fichero de entrada: " << std::strerror(errno) << '\n';
    }

    int n = -1;
    char buffer[1024];
    while(n != 0){
      n = read(fe, buffer ,1023);
      std::string str(buffer);
      str.copy(message.text.data(), message.text.size() - 1, 0); // copiamos
      socket.send_to(message, dest_address_c);  // enviamos
    }

    std::cout << "Ha terminado" << std::endl;
    close(fe);

  }catch (const std::exception& e) {
          eptr = std::current_exception();
  }

}

//Función recibir para el hilo.
void receive(Socket& socket, std::exception_ptr& eptr){
    sigset_t set;
    sigaddset(&set, SIGINT);
    sigaddset(&set, SIGTERM);
    sigaddset(&set, SIGHUP);


    pthread_sigmask(SIG_BLOCK, &set, nullptr);

    int fs = open("salida.txt", O_WRONLY);
    if(fs < 0){
      std::cerr << "No se pudo abrir el fichero de salida: " << std::strerror(errno) << '\n';
    }
  while(true){
    socket.receive_from(message,dest_address_s);
    std::cout << message.text.data() << std::endl;
    write(fs, message.text.data() , message.text.size()-1);
  }
  close(fs);
}

void request_cancellation(std::thread& thread){
  int thread_cancel = pthread_cancel(thread.native_handle());
  if(thread_cancel != 0){ //si retorna 0 el hilo fue cancelado sino retorna un numero distinto de 0.
    throw std::system_error(thread_cancel, std::system_category(), "Error en la cancelación de los hilos");
  }
}

void int_signal_handler(int signum){
  quit = true;
}

int protected_main(int argc, char* argv[]) {
  CommandLineArguments arguments(argc, argv);
  if (arguments.server_mode == true){
    std::signal(SIGINT, &int_signal_handler);
    std::signal(SIGTERM, &int_signal_handler);
    std::signal(SIGHUP, &int_signal_handler);

    local_address_s = make_ip_address(arguments.ip_client_dest, arguments.conn_port);
    dest_address_s = local_address_c;
    
    //excepciones de los hilos
    std::exception_ptr eptr_recv {};

    Socket socket_s(local_address_s);

    std::thread receive_thread(&receive, std::ref(socket_s), std::ref(eptr_recv));

    while (!quit);

    // request_cancellation(receive_thread);
    // receive_thread.join();

    if (eptr_recv) {
      std::rethrow_exception(eptr_recv);
    }

  } else if(arguments.client_mode == true){
    std::signal(SIGINT, &int_signal_handler);
    std::signal(SIGTERM, &int_signal_handler);
    std::signal(SIGHUP, &int_signal_handler);

    local_address_c = make_ip_address("",0);
    dest_address_c = make_ip_address(arguments.ip_client_dest, arguments.conn_port);

    std::exception_ptr eptr_send {};

    Socket socket_c(local_address_c);
    std::string str;

    int cont = 0;

    while (!quit){
      getline(std::cin,str);
      if (str == "/quit"){
        quit = true; // quit_app = quit (mejor limpieza)
      } else {
        std::string aux = str;
        std::thread* send_thread = new std::thread(&functionSend, std::ref(socket_c), std::ref(eptr_send), std::ref(aux));
        active_threads.insert(std::pair<int, std::thread *>(cont, send_thread));
        cont++;
      }
    }
      //request_cancellation(send_thread);
      //send_thread->join();

    if (eptr_send) {
      std::rethrow_exception(eptr_send);
    }
    
  }else if(arguments.show_help == true){ // Mostrando la ayuda 
      help();
  }
}

int main(int argc, char *argv[]){
  try{
    return protected_main(argc, argv);

  }catch(std::bad_alloc& e) {
          std::cerr << "mytalk" << ": memoria insuficiente\n";
          return 1;
      }
  catch(std::system_error& e) {
          std::cerr << "mitalk" << ": " << e.what() << '\n';
          return 2;
  }
  catch (...) {
      std::cout << "Error desconocido\n";
      return 99;
  }
  return 0;

}
