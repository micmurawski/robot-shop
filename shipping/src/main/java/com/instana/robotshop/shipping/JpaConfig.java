package com.instana.robotshop.shipping;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JpaConfig {
    private static final Logger logger = LoggerFactory.getLogger(JpaConfig.class);

    @Bean
    public DataSource getDataSource() {
        String host = System.getenv("DB_HOST") == null ? "localhost" : System.getenv("DB_HOST");
        String jdbcUrl = String.format(
                "jdbc:mysql://%s:3306/cities?useSSL=false&autoReconnect=true&allowPublicKeyRetrieval=true",
                host
        );

        logger.info("jdbc url {}", jdbcUrl);

        DataSourceBuilder<?> builder = DataSourceBuilder.create();
        builder.driverClassName("com.mysql.cj.jdbc.Driver");
        builder.url(jdbcUrl);
        builder.username("shipping");
        builder.password("secret");

        return builder.build();
    }
}
