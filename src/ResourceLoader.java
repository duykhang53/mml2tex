package com.github.transpect.mml2tex;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.regex.Pattern;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.URIResolver;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathFactory;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.Functions.FailableFunction;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.concurrent.Memoizer;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.client.utils.URIBuilder;
import org.apache.http.impl.client.HttpClientBuilder;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.ProcessingInstruction;
import org.xml.sax.SAXException;

public class ResourceLoader {

    private FailableFunction<HttpUriRequest, HttpResponse, Exception> httpExecutor = req -> HttpClientBuilder.create().build().execute(req);
    private XslImportTransformer xslImportTransformer = (href, targetUri) -> {
        if (Pattern.compile("[-\\w]+://").matcher(href).find()) {
            URIBuilder uriBuilder = new URIBuilder(href);
            if ("transpect.io".equals(uriBuilder.getHost())) {
                LinkedList<String> pathSegments = new LinkedList(uriBuilder.getPathSegments());

                if (pathSegments.isEmpty()) {
                    uriBuilder.setHost("transpect.github.io");
                } else {
                    String repoName = pathSegments.removeFirst();
                    Arrays.asList("master", repoName, "transpect").forEach(seg -> pathSegments.addFirst(seg));
                    uriBuilder.setScheme("https").setHost("raw.githubusercontent.com").setPathSegments(pathSegments);
                }

                return uriBuilder.build().toString();
            }
        } else if (targetUri != null) {
            URIBuilder uriBuilder = new URIBuilder(targetUri);
            String normalizedPath = FilenameUtils.normalize(uriBuilder.getPath() + "/../" + href, true);
            uriBuilder.setPath(normalizedPath);
            return uriBuilder.build().toString();
        }
        return href;
    };

    public FailableFunction<HttpUriRequest, HttpResponse, Exception> getHttpExecutor() {
        return httpExecutor;
    }

    public void setHttpExecutor(FailableFunction<HttpUriRequest, HttpResponse, Exception> httpExecutor) {
        this.httpExecutor = httpExecutor;
    }

    public XslImportTransformer getXslImportTransformer() {
        return xslImportTransformer;
    }

    public void setXslImportTransformer(XslImportTransformer xslImportTransformer) {
        this.xslImportTransformer = xslImportTransformer;
    }

    @SuppressWarnings("UseSpecificCatch")
    public static final Memoizer<String, XPathExpression> XPATH_MEMOIZER = new Memoizer<>(expr -> {
        try {
            return XPathFactory.newInstance().newXPath().compile(expr);
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    });

    public final Memoizer<String, byte[]> REMOTE_XSL_MEMOIZER = new Memoizer(key -> {
        try {
            String targetUri = (String) key;

            try (ByteArrayOutputStream contentBaos = new ByteArrayOutputStream()) {
                HttpResponse resp = httpExecutor.apply(new HttpGet(targetUri));
                IOUtils.copy(resp.getEntity().getContent(), contentBaos);

                try (ByteArrayInputStream bais = new ByteArrayInputStream(contentBaos.toByteArray())) {
                    byte[] content = normalizeTranspectUrl(bais, targetUri);
                    return content;
                }
            }
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }, true);

    public static Document createXmlDocument(byte[] content) throws IOException, ParserConfigurationException, SAXException {
        try (ByteArrayInputStream xmlStream = new ByteArrayInputStream(content)) {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            return factory.newDocumentBuilder().parse(xmlStream);
        }
    }

    public static String resolveTex(String xmlProc) throws IOException, ParserConfigurationException, SAXException {
        StringBuilder sb = new StringBuilder(xmlProc);

        if (xmlProc.trim().endsWith("?>")) {
            sb.append("<doc></doc>");
        }

        NodeList childNodes = createXmlDocument(sb.toString().getBytes()).getChildNodes();
        for (int i = 0; i < childNodes.getLength(); i++) {
            Node node = childNodes.item(i);
            if (node.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE) {
                ProcessingInstruction pi = (ProcessingInstruction) node;
                if ("mml2tex".equals(pi.getTarget())) {
                    return pi.getData();
                }
            }
        }

        return null;
    }

    public static InputStream loadResource(String resourcePath) {
        return ResourceLoader.class.getResourceAsStream(resourcePath);
    }

    public InputStream loadXsl() throws Exception {
        try (InputStream res = loadResource("/xsl/invoke-mml2tex.xsl")) {
            byte[] byt = this.normalizeTranspectUrl(res, null);
            return new ByteArrayInputStream(byt);
        }
    }

    public URIResolver createUriResolver() {
        return (href, base) -> {
            try {
                InputStream res;
                if (Pattern.compile("^https?://").matcher(href).find()) {
                    byte[] xslByte = REMOTE_XSL_MEMOIZER.compute(href);
                    res = new ByteArrayInputStream(xslByte);
                } else {
                    String resPath = FilenameUtils.normalize("/xsl/" + href, true);
                    res = ResourceLoader.loadResource(resPath);
                    byte[] xmlNormalized = normalizeTranspectUrl(res, null);
                    res = new ByteArrayInputStream(xmlNormalized);
                }

                return new StreamSource(res);
            } catch (Exception ex) {
                throw new RuntimeException(ex);
            }

        };
    }

    public static TransformerFactory createRegisteredTransformerFactory() throws TransformerFactoryConfigurationError {
        try {
            Class<TransformerFactory> saxonCls = (Class<TransformerFactory>) Class.forName("net.sf.saxon.TransformerFactoryImpl");
            return saxonCls.newInstance();
        } catch (ClassNotFoundException | InstantiationException | IllegalAccessException ex) {
            return TransformerFactory.newInstance();
        }
    }

    public static Transformer createTransformer(Source source, TransformerFactory factory) throws TransformerFactoryConfigurationError, TransformerConfigurationException {
        Transformer transformer = source != null ? factory.newTransformer(source) : factory.newTransformer();
        transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
        transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        return transformer;
    }

    public TransformerFactory createTransformerFactory() throws Exception {
        TransformerFactory factory = createRegisteredTransformerFactory();
        factory.setURIResolver(createUriResolver());
        return factory;
    }

    public Transformer createTransformer() throws Exception {
        return this.createTransformer(createTransformerFactory());
    }

    public Transformer createTransformer(TransformerFactory factory) throws Exception {
        return createTransformer(new StreamSource(loadXsl()), factory);
    }

    public String transform(String sourceXml) throws Exception {
        try (StringReader sr = new StringReader(sourceXml)) {
            return new String(transform(new StreamSource(sr)));
        }
    }

    public byte[] transform(Source source) throws Exception {
        Transformer transformer = this.createTransformer();

        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            StreamResult streamResult = new StreamResult(baos);
            transformer.transform(source, streamResult);
            return baos.toByteArray();
        }
    }

    public static String transform(String xml, Transformer transformer) throws Exception {
        if (xml == null) {
            return null;
        }

        try (StringReader sr = new StringReader(xml)) {
            StreamSource source = new StreamSource(sr);
            return transform(source, transformer);
        }
    }

    public static String transform(Source source, Transformer transformer) throws Exception {
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            StreamResult streamResult = new StreamResult(baos);
            transformer.transform(source, streamResult);
            return new String(baos.toByteArray());
        }
    }

    protected byte[] normalizeTranspectUrl(InputStream xmlContent, String targetUri) throws Exception {
        try (ByteArrayOutputStream contentBaos = new ByteArrayOutputStream()) {
            try {
                IOUtils.copy(xmlContent, contentBaos);
            } finally {
                xmlContent.close();
            }

            byte[] content = contentBaos.toByteArray();

            if (xslImportTransformer == null) {
                return content;
            }

            Document doc = createXmlDocument(content);
            XPathExpression xPathExpr = XPATH_MEMOIZER.compute("//*[local-name()='import' or local-name()='include']");
            NodeList importNodes = (NodeList) xPathExpr.evaluate(doc, XPathConstants.NODESET);

            boolean dirty = false;

            for (int i = 0; i < importNodes.getLength(); i++) {
                Node node = importNodes.item(i);

                if (!node.getNodeName().startsWith("xsl:")) {
                    continue;
                }

                Node hrefNode = node.getAttributes().getNamedItem("href");

                if (hrefNode == null) {
                    continue;
                }

                String newHref = xslImportTransformer.transform(hrefNode.getNodeValue(), targetUri);
                if (!StringUtils.equals(newHref, hrefNode.getNodeValue())) {
                    hrefNode.setNodeValue(newHref);
                    dirty = true;
                }
            }

            if (dirty) {
                Transformer transformer = createTransformerFactory().newTransformer();
                String transformedXml = transform(new DOMSource(doc), transformer);
                return transformedXml.getBytes();
            }

            return content;
        }
    }

    public static interface XslImportTransformer {

        String transform(String href, String targetUri) throws Exception;
    }
}
