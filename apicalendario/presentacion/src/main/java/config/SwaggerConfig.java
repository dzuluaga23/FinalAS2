package config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI configurarOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("API Calendario Laboral")
                        .description("Gestiona los tipos de día y el calendario laboral. "
                                + "Los festivos se consumen de la API Festivos (Node.js) y se "
                                + "persisten en PostgreSQL.")
                        .version("1.0.0"));
    }
}
