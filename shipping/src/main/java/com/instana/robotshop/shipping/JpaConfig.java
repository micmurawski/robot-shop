package com.instana.robotshop.shipping;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;

@Configuration
@EnableJpaRepositories(basePackages = "com.instana.robotshop.shipping")
@EnableTransactionManagement
public class JpaConfig {
    private static final Logger logger = LoggerFactory.getLogger(JpaConfig.class);

    @Bean
    @Primary
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSource dataSource() {
        String host = System.getenv("DB_HOST") == null ? "mysql" : System.getenv("DB_HOST");
        String port = System.getenv("DB_PORT") == null ? "3306" : System.getenv("DB_PORT");
        String username = System.getenv("DB_USER") == null ? "shipping" : System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD") == null ? "secret" : System.getenv("DB_PASSWORD");
        
        String jdbcUrl = String.format("jdbc:mysql://%s:%s/cities?useSSL=false&autoReconnect=true&allowPublicKeyRetrieval=true", 
            host, port);
        
        logger.info("Connecting to database at: {}", jdbcUrl);

        return DataSourceBuilder.create()
            .driverClassName("com.mysql.cj.jdbc.Driver")
            .url(jdbcUrl)
            .username(username)
            .password(password)
            .build();
    }
}
