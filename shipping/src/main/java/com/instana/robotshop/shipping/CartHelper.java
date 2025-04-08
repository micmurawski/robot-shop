package com.instana.robotshop.shipping;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.io.entity.StringEntity;

public class CartHelper {
    private static final Logger logger = LoggerFactory.getLogger(CartHelper.class);
    
    private String baseUrl;

    public CartHelper(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    // TODO - Remove deprecated calls
    public String addToCart(String id, String data) {
        logger.info("add shipping to cart {}", id);
        StringBuilder buffer = new StringBuilder();

        try (CloseableHttpClient httpClient = HttpClients.custom()
                .setDefaultRequestConfig(org.apache.hc.client5.http.config.RequestConfig.custom()
                    .setConnectTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
                    .build())
                .build()) {
            
            HttpPost postRequest = new HttpPost(baseUrl + id);
            StringEntity payload = new StringEntity(data, org.apache.hc.core5.http.ContentType.APPLICATION_JSON);
            postRequest.setEntity(payload);
            
            try (CloseableHttpResponse res = httpClient.execute(postRequest)) {
                if (res.getCode() == 200) {
                    try (BufferedReader in = new BufferedReader(new InputStreamReader(res.getEntity().getContent()))) {
                        String line;
                        while ((line = in.readLine()) != null) {
                            buffer.append(line);
                        }
                    }
                } else {
                    logger.warn("Failed with code {}", res.getCode());
                }
            }
        } catch(Exception e) {
            logger.warn("http client exception", e);
        }

        return buffer.toString();
    }
}
