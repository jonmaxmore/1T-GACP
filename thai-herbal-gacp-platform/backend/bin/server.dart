// ===================================================================
// Thai Herbal GACP Platform v3.0 - Backend Server
// ===================================================================

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:logging/logging.dart';
import 'package:dotenv/dotenv.dart';

// Core Services
import '../lib/core/config/app_config.dart';
import '../lib/core/database/database_service.dart';
import '../lib/core/middleware/middleware.dart';
import '../lib/core/utils/logger.dart';
import '../lib/core/security/security_service.dart';
import '../lib/core/monitoring/health_check.dart';

// Event Sourcing (Blockchain Alternative)
import '../lib/core/event_sourcing/event_store.dart';
import '../lib/core/tracking/tracking_service.dart';
import '../lib/core/digital_signature/signature_service.dart';

// API Routes
import '../lib/api/routes/auth_routes.dart';
import '../lib/api/routes/gacp_routes.dart';
import '../lib/api/routes/tracking_routes.dart';
import '../lib/api/routes/knowledge_routes.dart';
import '../lib/api/routes/admin_routes.dart';
import '../lib/api/routes/government_routes.dart';

// Services
import '../lib/services/gacp_service.dart';
import '../lib/services/ai_service.dart';
import '../lib/services/notification_service.dart';

// ===================================================================
// Global Variables
// ===================================================================

late final AppConfig config;
late final DatabaseService database;
late final EventStore eventStore;
late final TrackingService trackingService;
late final Logger logger;

// ===================================================================
// Main Server Function
// ===================================================================

Future<void> main(List<String> arguments) async {
  // Initialize logging
  _setupLogging();
  
  try {
    logger.info('🚀 Starting Thai Herbal GACP Backend Server v3.0');
    
    // Load environment configuration
    await _loadConfiguration();
    
    // Initialize core services
    await _initializeServices();
    
    // Setup server
    final server = await _setupServer();
    
    // Start server
    await _startServer(server);
    
    // Setup graceful shutdown
    _setupGracefulShutdown(server);
    
    logger.info('✅ Server started successfully on ${config.host}:${config.port}');
    
  } catch (error, stackTrace) {
    logger.severe('❌ Failed to start server: $error', error, stackTrace);
    exit(1);
  }
}

// ===================================================================
// Server Setup
// ===================================================================

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final timestamp = record.time.toIso8601String();
    final level = record.level.name;
    final message = record.message;
    final error = record.error != null ? ' | Error: ${record.error}' : '';
    
    print('[$timestamp] [$level] $message$error');
  });
  
  logger = Logger('ThaiHerbalGACPServer');
}

Future<void> _loadConfiguration() async {
  logger.info('📋 Loading configuration...');
  
  // Load environment variables
  var env = DotEnv();
  
  try {
    env.load(['../.env']);
  } catch (e) {
    logger.warning('Could not load .env file, using system environment');
  }
  
  // Initialize app configuration
  config = AppConfig.fromEnvironment(env);
  
  logger.info('✅ Configuration loaded - Environment: ${config.environment}');
}

Future<void> _initializeServices() async {
  logger.info('🛠️ Initializing services...');
  
  // Initialize database
  database = DatabaseService(config.databaseConfig);
  await database.initialize();
  
  // Initialize event store (replaces blockchain)
  eventStore = EventStore(database);
  await eventStore.initialize();
  
  // Initialize tracking service
  trackingService = TrackingService(eventStore);
  await trackingService.initialize();
  
  // Initialize security service
  await SecurityService.initialize(config.securityConfig);
  
  logger.info('✅ All services initialized');
}

Future<HttpServer> _setupServer() async {
  logger.info('⚙️ Setting up HTTP server...');
  
  // Create main router
  final router = Router();
  
  // Setup routes
  _setupRoutes(router);
  
  // Create handler pipeline
  final handler = const shelf.Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(_loggingMiddleware())
      .addMiddleware(_authMiddleware())
      .addMiddleware(_rateLimitMiddleware())
      .addMiddleware(_errorHandlingMiddleware())
      .addHandler(router);
  
  return await shelf_io.serve(
    handler,
    config.host,
    config.port,
    securityContext: config.useSSL ? _createSecurityContext() : null,
  );
}

void _setupRoutes(Router router) {
  logger.info('🛣️ Setting up API routes...');
  
  // Health check endpoint
  router.get('/health', _healthCheckHandler);
  router.get('/ready', _readinessCheckHandler);
  
  // API Documentation
  router.get('/docs', _docsHandler);
  router.get('/api-docs', _apiDocsHandler);
  
  // Static files
  router.mount('/static/', createStaticHandler('../public'));
  
  // WebSocket endpoint
  router.get('/ws', webSocketHandler(_handleWebSocket));
  
  // API Routes
  _mountApiRoutes(router);
  
  // Catch all 404
  router.all('/<path|.*>', _notFoundHandler);
}

void _mountApiRoutes(Router router) {
  // Authentication routes
  router.mount('/api/v1/auth/', AuthRoutes().router);
  
  // GACP Certification routes
  router.mount('/api/v1/gacp/', GacpRoutes().router);
  
  // Tracking routes (Event Sourcing based)
  router.mount('/api/v1/tracking/', TrackingRoutes().router);
  
  // Knowledge Graph routes
  router.mount('/api/v1/knowledge/', KnowledgeRoutes().router);
  
  // Government API routes
  router.mount('/api/v1/government/', GovernmentRoutes().router);
  
  // Admin routes
  router.mount('/api/v1/admin/', AdminRoutes().router);
}

Future<HttpServer> _startServer(HttpServer server) async {
  logger.info('🌐 Server listening on ${config.host}:${config.port}');
  
  if (config.useSSL) {
    logger.info('🔒 SSL/TLS enabled');
  }
  
  return server;
}

// ===================================================================
// Middleware
// ===================================================================

shelf.Middleware _corsMiddleware() {
  return corsHeaders(
    headers: {
      'Access-Control-Allow-Origin': config.allowedOrigins.join(','),
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
    },
  );
}

shelf.Middleware _loggingMiddleware() {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      final start = DateTime.now();
      final response = await innerHandler(request);
      final duration = DateTime.now().difference(start);
      
      logger.info(
        '${request.method} ${request.url} - ${response.statusCode} '
        '(${duration.inMilliseconds}ms)',
      );
      
      return response;
    };
  };
}

shelf.Middleware _authMiddleware() {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      // Skip auth for public endpoints
      if (_isPublicEndpoint(request.url.path)) {
        return await innerHandler(request);
      }
      
      // Verify JWT token
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return shelf.Response.unauthorized('Missing or invalid authorization header');
      }
      
      final token = authHeader.substring(7);
      
      try {
        final payload = await SecurityService.verifyJWT(token);
        final requestWithUser = request.change(context: {'user': payload});
        return await innerHandler(requestWithUser);
      } catch (e) {
        return shelf.Response.unauthorized('Invalid token');
      }
    };
  };
}

shelf.Middleware _rateLimitMiddleware() {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      // Implement rate limiting logic
      final clientIp = request.headers['x-forwarded-for'] ?? 
                      request.headers['x-real-ip'] ?? 
                      'unknown';
      
      if (await _isRateLimited(clientIp)) {
        return shelf.Response(429, body: 'Rate limit exceeded');
      }
      
      return await innerHandler(request);
    };
  };
}

shelf.Middleware _errorHandlingMiddleware() {
  return (shelf.Handler innerHandler) {
    return (shelf.Request request) async {
      try {
        return await innerHandler(request);
      } catch (error, stackTrace) {
        logger.severe('Unhandled error: $error', error, stackTrace);
        
        return shelf.Response.internalServerError(
          body: json.encode({
            'error': 'Internal server error',
            'message': config.isDevelopment ? error.toString() : 'Something went wrong',
            'timestamp': DateTime.now().toIso8601String(),
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

// ===================================================================
// Route Handlers
// ===================================================================

Future<shelf.Response> _healthCheckHandler(shelf.Request request) async {
  final healthCheck = HealthCheck();
  final status = await healthCheck.check();
  
  return shelf.Response.ok(
    json.encode(status),
    headers: {'content-type': 'application/json'},
  );
}

Future<shelf.Response> _readinessCheckHandler(shelf.Request request) async {
  // Check if all services are ready
  final isReady = await database.isConnected() && 
                  await eventStore.isReady();
  
  if (isReady) {
    return shelf.Response.ok(
      json.encode({'status': 'ready', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'content-type': 'application/json'},
    );
  } else {
    return shelf.Response.serviceUnavailable(
      json.encode({'status': 'not ready', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<shelf.Response> _docsHandler(shelf.Request request) async {
  // Serve API documentation
  return shelf.Response.ok(
    '''
    <!DOCTYPE html>
    <html>
      <head>
        <title>Thai Herbal GACP API Documentation</title>
        <link rel="stylesheet" type="text/css" href="/static/swagger-ui.css" />
      </head>
      <body>
        <div id="swagger-ui"></div>
        <script src="/static/swagger-ui-bundle.js"></script>
        <script>
          SwaggerUIBundle({
            url: '/api-docs',
            dom_id: '#swagger-ui',
            presets: [
              SwaggerUIBundle.presets.apis,
              SwaggerUIBundle.presets.standalone
            ]
          });
        </script>
      </body>
    </html>
    ''',
    headers: {'content-type': 'text/html'},
  );
}

Future<shelf.Response> _apiDocsHandler(shelf.Request request) async {
  // Return OpenAPI specification
  final apiSpec = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Thai Herbal GACP API',
      'version': '3.0.0',
      'description': 'API for Thai Herbal GACP Certification Platform',
    },
    'servers': [
      {'url': 'https://api.thaiherbalgacp.com/api/v1'},
      {'url': 'http://localhost:${config.port}/api/v1'},
    ],
    'paths': {
      // API paths will be defined here
    },
  };
  
  return shelf.Response.ok(
    json.encode(apiSpec),
    headers: {'content-type': 'application/json'},
  );
}

Future<shelf.Response> _notFoundHandler(shelf.Request request) async {
  return shelf.Response.notFound(
    json.encode({
      'error': 'Not Found',
      'message': 'The requested resource was not found',
      'path': request.url.path,
      'timestamp': DateTime.now().toIso8601String(),
    }),
    headers: {'content-type': 'application/json'},
  );
}

// ===================================================================
// WebSocket Handler
// ===================================================================

void _handleWebSocket(WebSocketChannel webSocket) {
  logger.info('🔌 New WebSocket connection established');
  
  webSocket.stream.listen(
    (message) {
      logger.info('📨 WebSocket message received: $message');
      
      // Handle different message types
      try {
        final data = json.decode(message as String);
        _processWebSocketMessage(webSocket, data);
      } catch (e) {
        logger.warning('Invalid WebSocket message format: $message');
        webSocket.sink.add(json.encode({
          'type': 'error',
          'message': 'Invalid message format',
        }));
      }
    },
    onDone: () {
      logger.info('🔌 WebSocket connection closed');
    },
    onError: (error) {
      logger.warning('🔌 WebSocket error: $error');
    },
  );
}

void _processWebSocketMessage(WebSocketChannel webSocket, Map<String, dynamic> data) {
  final type = data['type'] as String?;
  
  switch (type) {
    case 'ping':
      webSocket.sink.add(json.encode({'type': 'pong'}));
      break;
    case 'subscribe':
      // Handle subscription to real-time updates
      break;
    case 'unsubscribe':
      // Handle unsubscription
      break;
    default:
      webSocket.sink.add(json.encode({
        'type': 'error',
        'message': 'Unknown message type: $type',
      }));
  }
}

// ===================================================================
// Helper Functions
// ===================================================================

bool _isPublicEndpoint(String path) {
  final publicPaths = [
    '/health',
    '/ready',
    '/docs',
    '/api-docs',
    '/api/v1/auth/login',
    '/api/v1/auth/register',
    '/static/',
  ];
  
  return publicPaths.any((publicPath) => path.startsWith(publicPath));
}

Future<bool> _isRateLimited(String clientIp) async {
  // Implement rate limiting logic using Redis or in-memory store
  // For now, return false (no rate limiting)
  return false;
}

SecurityContext? _createSecurityContext() {
  if (!config.useSSL) return null;
  
  final context = SecurityContext();
  context.useCertificateChain(config.sslCertPath!);
  context.usePrivateKey(config.sslKeyPath!);
  
  return context;
}

// ===================================================================
// Graceful Shutdown
// ===================================================================

void _setupGracefulShutdown(HttpServer server) {
  // Handle shutdown signals
  ProcessSignal.sigint.watch().listen((_) async {
    logger.info('🛑 Received SIGINT, shutting down gracefully...');
    await _shutdown(server);
  });
  
  ProcessSignal.sigterm.watch().listen((_) async {
    logger.info('🛑 Received SIGTERM, shutting down gracefully...');
    await _shutdown(server);
  });
}

Future<void> _shutdown(HttpServer server) async {
  try {
    logger.info('🔄 Closing server connections...');
    await server.close(force: false);
    
    logger.info('🗄️ Closing database connections...');
    await database.close();
    
    logger.info('📦 Closing event store...');
    await eventStore.close();
    
    logger.info('✅ Server shutdown completed');
    exit(0);
  } catch (error) {
    logger.severe('❌ Error during shutdown: $error');
    exit(1);
  }
}
