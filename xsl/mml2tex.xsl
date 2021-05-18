<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
  xmlns:xs="http://www.w3.org/2001/XMLSchema"  
  xmlns:tr="http://transpect.io"
  xmlns:mml="http://www.w3.org/1998/Math/MathML" 
  xmlns:mml2tex="http://transpect.io/mml2tex"
  xmlns:xml2tex="http://transpect.io/xml2tex"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:functx="http://www.functx.com"
  exclude-result-prefixes="tr mml xs mml2tex" 
  xpath-default-namespace="http://www.w3.org/1998/Math/MathML" 
  version="2.0">

  <xsl:import href="function-names.xsl"/>

  <xsl:output method="text" encoding="UTF-8"/>
  
  <xsl:param name="fail-on-error" select="'yes'"/><!-- yes|no -->

  <xsl:param name="set-math-style" select="'no'"/><!-- yes|no -->

  <xsl:param name="always-use-left-right" select="'no'"/><!-- yes|no -->
  
  <xsl:param name="use-upgreek-map" as="xs:boolean" select="true()"/>
  
  <xsl:param name="katex" select="'no'" as="xs:string"/>
  <xsl:param name="katex-class" as="xs:string" select="'tr--katex'"/>
  
  <xsl:param name="texmap-uri" select="'../texmap/texmap.xml'" as="xs:string"/>
  
  <xsl:param name="texmap-upgreek-uri" select="'../texmap/texmap-upgreek.xml'" as="xs:string"/>
  
  <xsl:variable name="texmap" select="document($texmap-uri)/xml2tex:set/xml2tex:charmap/xml2tex:char" as="element(xml2tex:char)+"/>
  
  <xsl:variable name="texmap-upgreek" select="document($texmap-upgreek-uri)/xml2tex:set/xml2tex:charmap/xml2tex:char" as="element(xml2tex:char)*"/>
  
  <xsl:variable name="texregex" as="xs:string"
                select="concat('[', functx:escape-for-regex(string-join(for $i in $texmap/@character return $i, '')), ']')"/>

  <xsl:variable name="texregex-upgreek" as="xs:string"
                select="concat('[', functx:escape-for-regex(string-join(for $i in $texmap-upgreek/@character return $i, '')), ']+')" />

  <xsl:variable name="diacritics-regex" select="'^[&#x60;&#xA8;&#xB4;&#xb8;&#x2c6;&#x2c7;&#x2d8;-&#x2dd;&#x300;-&#x338;&#x20d0;-&#x20ef;]$'" as="xs:string"/>
  
  <xsl:variable name="parenthesis-regex" select="'[\[\]\(\){}&#x2308;&#x2309;&#x230a;&#x230b;&#x2329;&#x232a;&#x27e8;&#x27e9;&#x3008;&#x3009;]'" as="xs:string"/>

  <xsl:variable name="whitespace-regex" select="'\p{Zs}&#x200b;-&#x200f;'" as="xs:string"/>

  <xsl:template match="*" mode="mathml2tex" priority="-10">
    <xsl:message terminate="{$fail-on-error}" select="'[ERROR]: unknown element', name()"/>    
  </xsl:template>

  <xsl:template match="@*" mode="mathml2tex">
    <xsl:message terminate="{$fail-on-error}" select="'[ERROR]: unknown attribute', name()"/>
  </xsl:template>

  <xsl:template match="math" mode="mathml2tex">
    <xsl:variable name="basic-transformation">
      <xsl:apply-templates select="@display, node()" mode="#current"/>
    </xsl:variable>
    <xsl:value-of select="$basic-transformation"/>
  </xsl:template>
  <!-- Switch to “always create \limits after integral signs etc.” in an importing stylesheet:
  <xsl:template match="mml:math" mode="mathml2tex">
    <xsl:next-match>
      <xsl:with-param name="create-limits" as="xs:boolean" select="true()" tunnel="yes"/>
    </xsl:next-match>
  </xsl:template> -->

  <xsl:template match="math/@display" mode="mathml2tex">
    <xsl:if test="$set-math-style = 'yes'">
      <xsl:choose>
        <xsl:when test=". = 'inline'">
          <xsl:text>\textstyle </xsl:text>
        </xsl:when>
        <xsl:when test=". = 'block'">
          <xsl:text>\displaystyle </xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message
            select="'[WARNING]: attribute', name(), 'in', ../name(), 'must be ''inline'' or ''block''! Was:', ."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="semantics" mode="mathml2tex">
    <xsl:apply-templates select="@*, node()" mode="#current"/>
  </xsl:template>

  <!-- drop attributes and elements -->
  <xsl:template match="@overflow[parent::math]
                      |@movablelimits[parent::mo]
                      |@mathcolor
                      |@color
                      |@fontsize
                      |@mathsize
                      |@mathbackground
                      |@background
                      |@maxsize
                      |@minsize
                      |@scriptminsize
                      |@fence
                      |@stretchy
                      |@separator
                      |@accent
                      |@accentunder
                      |@form
                      |@largeop
                      |@lspace
                      |@rspace
                      |@columnalign[parent::mtable]
                      |@align[parent::mtable]
                      |@accent
                      |@accentunder
                      |@form
                      |@largeop
                      |@lspace
                      |@rspace
                      |@linebreak
                      |@symmetric[parent::mo]
                      |@columnspacing
                      |@rowspacing
                      |@columnalign
                      |@groupalign
                      |@columnwidth
                      |@rowalign
                      |@displaystyle
                      |@scriptlevel[parent::mstyle]
                      |@linethickness[parent::mstyle]
                      |@columnlines
                      |@rowlines
                      |@equalcolumns
                      |@equalrows
                      |@frame
                      |@framespacing
                      |@rowspan
                      |@class
                      |@side" mode="mathml2tex">
    <xsl:message select="'[WARNING]: attribute', name(), 'in context', ../name(), 'ignored!'"/>
  </xsl:template>
  
  <xsl:template match="mphantom|maligngroup" mode="mathml2tex">
    <xsl:message select="'[WARNING]: element', name(), 'ignored!'"/>
  </xsl:template>
  
  <!-- https://github.com/transpect/mml2tex/issues/3 -->
  
  <xsl:template match="malignmark|maligngroup[position() ne 1]" mode="mathml2tex">
    <!-- consider that the stylesheet which imports mm2ltex.xsl must 
         wrap the equation with an align environment -->
    <xsl:text>&#x20;&amp;&#x20;</xsl:text>
  </xsl:template>
  
  <!-- resolve elements -->
  
  <xsl:template match="mlabeledtr|maction|mrow|merror|mpadded" mode="mathml2tex">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="mspace[@width]" mode="mathml2tex">
    <xsl:variable name="width" select="xs:decimal(replace(@width, '[a-z]+', ''))" as="xs:decimal"/>
    <xsl:variable name="mu-width" select="$width * 18" as="xs:decimal"/>
    <!-- 1 mu = 1/18em, MathML authors are encouraged to use em as unit here -->
    <xsl:variable name="tex-mwidth" select="if($mu-width &gt;= 36)  then '\qquad '  (: twice of \quad (= 36 mu):)
                                       else if($mu-width &gt;= 18)  then '\quad '   (: 1 mu :)
                                       else if($mu-width &gt;= 9)   then '\ '       (: equivalent of space in normal text :)
                                       else if($mu-width &gt;= 5)   then '\;'       (: 5/18 of \quad (= 5 mu) :)
                                       else if($mu-width &gt;= 4)   then '\:'       (: 4/18 of \quad (= 3 mu) :)
                                       else if($mu-width &lt; 4)    then '\,'       (: 3/18 of \quad (= 3 mu) :)
                                       else '\ '"/>
    <xsl:choose>
      <xsl:when test="@width">
        <xsl:apply-templates select="@* except (@width, @height, @depth)" mode="#current"/>
        <xsl:apply-templates mode="#current"/>
        <xsl:value-of select="$tex-mwidth"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="@* except (@width, @height, @depth)" mode="#current"/>
        <xsl:apply-templates mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mspace[@linebreak]" mode="mathml2tex">
    <xsl:if test="@linebreak eq 'newline'">
      <xsl:text>\newline&#x20;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="menclose" mode="mathml2tex">
    <xsl:value-of select="tr:menclose-to-latex(@notation)[1]"/>
    <xsl:apply-templates mode="#current"/>
    <xsl:value-of select="tr:menclose-to-latex(@notation)[2]"/>
  </xsl:template>
  
  <xsl:function name="tr:menclose-to-latex" as="xs:string+">
    <xsl:param name="notation" as="attribute(notation)"/>
    <xsl:sequence select="if($notation = ('box', 'roundedbox'))  then ('\boxed{',      '}')
                      else if($notation eq 'updiagonalstrike')   then ('\cancel{',     '}')
                      else if($notation eq 'downdiagonalstrike') then ('\bcancel{',    '}')
                      else if($notation eq 'updiagonalarrow')    then ('\cancelto{}',  '}')
                      else if($notation eq 'top')                then ('\overline{',   '}')
                      else if($notation eq 'underline')          then ('\underline{',  '}')
                      else if($notation eq 'left')               then ('\left|',       '\right.')
                      else if($notation eq 'right')              then ('\left.',       '\right|')
                      else if($notation eq 'radical')            then ('\sqrt{',       '}')
                      else                                            (concat('\', $notation, '{'), '}')"/>
  </xsl:function>
  

  <xsl:template match="mfrac" mode="mathml2tex">
    <xsl:choose>
      <xsl:when test="@bevelled eq 'true' and $katex eq 'yes'">
        <xsl:choose>
          <xsl:when test="count(*) eq 2">
            <xsl:apply-templates select="*[1]" mode="#current"/>
            <xsl:text>/</xsl:text>
            <xsl:apply-templates select="*[2]" mode="#current"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="{$fail-on-error}" select="name(), 'must include two elements', 'context:&#xa;', ."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="if(@linethickness eq '0pt')   then '\genfrac{}{}{0pt}{}'
          else if (@bevelled eq 'true') then '\sfrac'
          else                               '\frac'"/>
        <xsl:apply-templates select="@*[not(local-name() = ('linethickness', 'bevelled'))]" mode="#current"/>
        <xsl:choose>
          <xsl:when test="count(*) eq 2">
            <xsl:text>{</xsl:text>
            <xsl:apply-templates select="*[1]" mode="#current"/>
            <xsl:text>}{</xsl:text>
            <xsl:apply-templates select="*[2]" mode="#current"/>
            <xsl:text>}</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="{$fail-on-error}" select="name(), 'must include two elements', 'context:&#xa;', ."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="mmultiscripts" mode="mathml2tex">
    <xsl:choose>
      <xsl:when test="$katex = 'yes'">
        <xsl:variable name="base" select="./node()[1]"/>
        <xsl:variable name="pre"  select=".//(*:mn|*:mrow)[preceding-sibling::*:mprescripts]"/>
        <xsl:variable name="post" select=".//(*:mn|*:mrow)[following-sibling::*:mprescripts] except $base"/>
        
        <xsl:text>{}^{</xsl:text>
        <!-- pre -->
        <xsl:apply-templates select="$pre[2]" mode="#current"/>
        <xsl:text>}_{</xsl:text>
        <xsl:apply-templates select="$pre[1]" mode="#current"/>
        <xsl:text>}{</xsl:text>
        
        <!-- base -->
        <xsl:text>}{</xsl:text>
        <xsl:apply-templates select="$base" mode="#current"/>
        <xsl:text>}^{</xsl:text>
        
        <!-- post -->
        <xsl:apply-templates select="$post[2]" mode="#current"/>
        <xsl:text>}_{</xsl:text>
        <xsl:apply-templates select="$post[1]" mode="#current"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        
      <!-- 
      the tensor command relies on the same-named LaTeX package
      https://www.ctan.org/pkg/tensor
      -->
        
        <xsl:text>\tensor*[</xsl:text>
        <!-- pre -->
        <xsl:for-each-group select="node()" group-by="preceding-sibling::mprescripts">
          <xsl:for-each select="current-group()">
            <xsl:call-template name="apply-superscript-or-subscript"/>
          </xsl:for-each>
        </xsl:for-each-group>
        <!-- base -->
        <xsl:text>]{</xsl:text>
        <xsl:apply-templates select="*[1]" mode="#current"/>
        <xsl:text>}{</xsl:text>
        <!-- post -->
        <xsl:for-each-group select="node()[not(position() eq 1)]" group-by="following-sibling::mprescripts">
          <xsl:for-each select="current-group()">
            <xsl:call-template name="apply-superscript-or-subscript"/>
          </xsl:for-each>
        </xsl:for-each-group>
        <xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="apply-superscript-or-subscript">
    <xsl:choose>
      <xsl:when test="position() mod 2 eq 0">
        <xsl:text>^{</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="position() mod 2 eq 1">
        <xsl:text>_{</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="msqrt" mode="mathml2tex">
    <xsl:text>\sqrt{</xsl:text>
    <xsl:apply-templates mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="mroot" mode="mathml2tex">
    <xsl:if test="count(*) ne 2">
      <xsl:message terminate="{$fail-on-error}" select="name(), 'must include two elements', 'context:&#xa;', ancestor::math[1]"/>
    </xsl:if>
    <xsl:text>\sqrt</xsl:text>
    <!-- index (optional) -->
    <xsl:if test="*[2]/node()">
      <xsl:text>[</xsl:text>  
      <xsl:apply-templates select="*[2]" mode="#current"/>
      <xsl:text>]</xsl:text>
    </xsl:if>
    <!-- radicand -->
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="msup|msub" mode="mathml2tex">
    <xsl:if test="count(*) ne 2">
      <xsl:message terminate="{$fail-on-error}" select="name(), 'must include two elements', 'context:&#xa;', ancestor::math[1]"/>
    </xsl:if>
    <xsl:if test="parent::msub | parent::msup | parent::mrow/(parent::msub, parent::msup)">{</xsl:if>
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <xsl:value-of select="if (local-name(.) eq 'msup') then '^' else '_'"/>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="*[2]" mode="#current"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="parent::msub | parent::msup | parent::mrow/(parent::msub, parent::msup)">}</xsl:if>
  </xsl:template>
  
  <!-- primes, such as y'' -->
  
  <xsl:template match="msup[mi[1] and *[2] and matches(*[2], '^[''&#x2032;&#x2033;&#x2034;]$')]" mode="mathml2tex">
    <xsl:if test="count(*) ne 2">
      <xsl:message terminate="{$fail-on-error}" select="name(), 'must include two elements', 'context:&#xa;', ancestor::math[1]"/>
    </xsl:if>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:variable name="integrals-sums-and-limits" as="xs:string+" 
                select="'&#x220f;', 
                        '&#x2210;', 
                        '&#x2211;', 
                        '&#x222b;',
                        '&#x222c;',
                        '&#x222d;',
                        '&#x222e;',
                        '&#x222f;',
                        '&#x2230;',
                        '&#x22c0;', 
                        '&#x22c1;', 
                        '&#x22c2;', 
                        '&#x22c3;', 
                        'lim', 
                        'max', 
                        'min'"/>

  <xsl:template match="msubsup|munderover[*[1] = $integrals-sums-and-limits]" mode="mathml2tex">
    <xsl:param name="create-limits" as="xs:boolean?" tunnel="yes"/>
    <xsl:if test="count(*) ne 3">
      <xsl:message terminate="{$fail-on-error}" select="name(), 'must include three elements', 'context:&#xa;', ancestor::math[1]"/>
    </xsl:if>
    <xsl:variable name="base">
      <xsl:apply-templates select="*[1]" mode="#current"/>
    </xsl:variable>
    <xsl:if test="matches($base, '^.*_\{[^}]*\}+$')">
      <xsl:text>{</xsl:text>
    </xsl:if>
    <xsl:sequence select="$base"/>
    <xsl:if test="matches($base, '^.*_\{[^}]*\}+$')">
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="$create-limits and *[1] = $integrals-sums-and-limits">
      <xsl:text>\limits</xsl:text>
    </xsl:if>
    <xsl:text>_{</xsl:text>
    <xsl:apply-templates select="*[2]" mode="#current"/>
    <xsl:text>}^{</xsl:text>
    <xsl:apply-templates select="*[3]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="mtable" mode="mathml2tex">
    <xsl:variable name="mcc" select="mml2tex:max-col-count(.)" as="xs:integer"/>
    <xsl:variable name="columnlines" select="tokenize(@columnlines, '\s')" as="xs:string*"/>
    <xsl:variable name="col-aligns" select="for $i in mtr[count((mtd, .//malignmark)) &gt;= $mcc]
                                            return ($i/mtd/ancestor-or-self::*[@columnalign]/@columnalign, 
                                                    $i/mtd/ancestor-or-self::*[@groupalign]/@groupalign, 
                                                    'center')[1]" as="xs:string*"/>
    <xsl:text>\begin{array}{</xsl:text>
    <xsl:for-each select="1 to $mcc">
      <xsl:variable name="pos" select="min((count($col-aligns), position()))" as="xs:integer"/>
      <xsl:value-of select="substring($col-aligns[$pos], 1, 1)"/>
      <xsl:choose>
        <xsl:when test="$columnlines[$pos] eq 'dashed'">
          <xsl:text>:</xsl:text>
        </xsl:when>
        <xsl:when test="$columnlines[$pos] eq 'solid'">
          <xsl:text>|</xsl:text>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:for-each>
    <xsl:text>}&#xa;</xsl:text>
    <xsl:apply-templates select="@* except @width" mode="#current"/>
    <xsl:apply-templates mode="#current"/>
    <xsl:text>\end{array}</xsl:text>
  </xsl:template>
  
  <xsl:function name="mml2tex:max-col-count" as="xs:integer">
    <xsl:param name="mtable" as="element(mtable)"/>
    <xsl:sequence select="max(for $i in $mtable/mtr return count(($i/mtd, $i//malignmark)))"/>
  </xsl:function>

  <xsl:template match="mtr" mode="mathml2tex">
    <xsl:variable name="position" select="count(preceding-sibling::mtr) + 1" as="xs:integer"/>
    <xsl:variable name="rowlines" select="tokenize(parent::mtable/@rowlines, '\s')" as="xs:string*"/>
    <xsl:apply-templates select="@*, node()" mode="#current"/>
    <xsl:if test="following-sibling::mtr">
      <xsl:text>\\</xsl:text>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$rowlines[$position] = 'solid'">
        <xsl:text>&#xa;\hline&#xa;</xsl:text>  
      </xsl:when>
      <xsl:when test="$rowlines[$position] = 'dashed'">
         <xsl:message select="'[WARNING]: arydshln package is needed to draw dashed lines in arrays'"/>
        <xsl:text>&#xa;\hdashline&#xa;</xsl:text>  
      </xsl:when>
    </xsl:choose>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>

  <xsl:template match="mtd" mode="mathml2tex">
    <xsl:apply-templates select="@*, node()" mode="#current"/>
    <xsl:if test="following-sibling::mtd">
      <xsl:text> &amp; </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="mover|munder" mode="mathml2tex">
    <xsl:if test="count(*) ne 2">
      <xsl:message terminate="{$fail-on-error}" select="name(), 'must include two elements', 'context:&#xa;', ancestor::math[1]"/>
    </xsl:if>
    <!-- diacritical mark overline should be substituted with latex overline -->
    <xsl:variable name="expression" select="*[1]" as="element(*)"/>
    <xsl:variable name="accent" select="*[2]" as="element(*)"/>
    <xsl:variable name="is-diacritical-mark" select="matches($accent, $diacritics-regex) 
                                                     (:and (not(matches($accent, '&#xaf;') and self::munder))  :)" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="$accent eq '&#xb8;' and self::munder">
        <xsl:value-of select="'\text{\c{'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x2c6;' and self::mover">
        <xsl:value-of select="'\hat'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x2c7;' and self::mover">
        <xsl:value-of select="'\check'"/>
      </xsl:when>
      <xsl:when test="$accent = ('&#x23de;', '&#x23df;', '&#xfe37;', '&#xfe38;')">
        <xsl:value-of select="if(self::mover) then '\overbrace' else '\underbrace'"/>
      </xsl:when>
      <xsl:when test="$accent = ('&#x23b4;', '&#x23b5;', '&#xfe47;', '&#xfe48;')">
        <xsl:value-of select="if(self::mover) then '\overbracket' else '\underbracket'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x2dd;' and self::mover">
        <xsl:value-of select="'\text{\H{'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x5e;' and self::mover"><!-- superscript circumflex/caret -->
        <xsl:value-of select="if(string-length($expression) gt 1) then '\widehat' else '\hat'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x7e;' and self::mover"><!-- superscript tilde -->
        <xsl:value-of select="if(string-length($expression) gt 1) then '\widetilde' else '\tilde'"/>
      </xsl:when>
      <xsl:when test="$accent = ('&#x2d9;') and self::mover"><!-- \dot -->
        <xsl:value-of select="'\dot'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#xa8;' and self::mover"><!-- \ddot -->
        <xsl:value-of select="'\ddot'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x20db;' and self::mover"><!-- \dddot -->
        <xsl:value-of select="'\dddot'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x20dc;' and self::mover"><!-- \ddddot -->
        <xsl:value-of select="'\ddddot'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x60;' and self::mover"><!-- \ddot -->
        <xsl:value-of select="'\grave'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#xb4;' and self::mover"><!-- acute accent -->
        <xsl:value-of select="'\acute'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x2d8;' and self::mover"><!-- breve accent -->
        <xsl:value-of select="'\breve'"/>
      </xsl:when>
      <xsl:when test="$accent eq '&#x2da;' and self::mover">
        <xsl:value-of select="'\mathring'"/>
      </xsl:when>
      <xsl:when test="matches($accent, '^[&#xaf;&#x5f;&#x304;&#x305;&#x203e;]$')"><!-- macron, combining macron, combining overline -->
        <xsl:value-of select="if(self::mover ) then '\overline' else '\underline'"/>
      </xsl:when>
      <xsl:when test="$is-diacritical-mark">
        <xsl:apply-templates select="$accent" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="if(self::mover ) then '\overset{' else '\underset{'"/>
        <xsl:apply-templates select="$accent" mode="#current"/>
        <xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>{</xsl:text>
    <xsl:apply-templates select="$expression" mode="#current"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="$accent = ('&#x2dd;', '&#xb8;')">
      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="munderover" mode="mathml2tex">
    <xsl:if test="count(*) ne 3">
      <xsl:message terminate="{$fail-on-error}" select="name(), 'must include three elements', 'context:&#xa;', ancestor::math[1]"/>
    </xsl:if>
    <xsl:text>\overset{</xsl:text>
    <xsl:apply-templates select="*[3]" mode="#current"/>
    <xsl:text>}{\underset{</xsl:text>
    <xsl:apply-templates select="*[2]" mode="#current"/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="mover[*[1] = $integrals-sums-and-limits]
                      |munder[*[1] = $integrals-sums-and-limits]" mode="mathml2tex">
    <xsl:param name="create-limits" as="xs:boolean?" tunnel="yes"/>
    <xsl:if test="count(*) ne 2">
      <xsl:message terminate="{$fail-on-error}" select="name(), 'must include two elements', 'context:&#xa;', ancestor::math[1]"/>
    </xsl:if>
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <xsl:if test="$create-limits">
      <xsl:text>\limits</xsl:text>
    </xsl:if>
    <xsl:value-of select="concat(if(self::mover) then '^' else '_', '{')"/>
    <xsl:apply-templates select="*[2]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="mfenced[count(mrow/mtable[every $r in mtr satisfies count($r/mtd) le 2]) = 1]
                              [count(*) = 1]
                              [@open = '{']
                              [@close = '']"
                mode="mathml2tex">
    <xsl:apply-templates select="mrow/*[following-sibling::mtable]" mode="#current"/>
    <xsl:text>\begin{cases}
    </xsl:text>
    <xsl:apply-templates select="mrow/mtable/mtr" mode="#current"/>
    <xsl:text>\end{cases}
    </xsl:text>
    <xsl:apply-templates select="mrow/*[preceding-sibling::mtable]" mode="#current"/>
  </xsl:template>
  
  <!-- https://github.com/transpect/mml2tex/issues/1, requires amsmath -->
  
  <xsl:template match="mfenced[count(*) eq 1][count(mrow) eq 1][mrow/mfrac[@linethickness = ('0', '0pt')]][count(mrow/mfrac/*) eq 2]
                      |mfenced[count(*) eq 1][count(mfrac) eq 1][mfrac[@linethickness = ('0', '0pt')]][count(mfrac/*) eq 2]" mode="mathml2tex">
    <xsl:text>\binom{</xsl:text>
    <xsl:apply-templates select="(mrow/mfrac/*, mfrac/*)[1]" mode="#current"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="(mrow/mfrac/*, mfrac/*)[2]" mode="#current"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="mfenced" mode="mathml2tex">
    <xsl:call-template name="fence">
      <xsl:with-param name="pos" select="'left'"/>
      <xsl:with-param name="val" select="(@open, '(')[1]"/>
    </xsl:call-template>
    <xsl:variable name="my-seps" select="replace(@separators, '\s+', '')" as="xs:string"/>
    <xsl:variable name="seps" select="if(not(@separators))
                                        then ',' (: mathml spec: comma if @separators didn't exist :)
                                      else if(normalize-space(@separators)) 
                                        then for $x in (1 to string-length($my-seps)) return substring($my-seps, $x, 1)
                                      else '' (: empty @separators is ignored :)" as="xs:string*"/>
    <xsl:variable name="els" select="*"/>
    <xsl:for-each select="1 to count($els)">
      <xsl:if test="current() &gt; 1">
        <xsl:value-of select="if (empty($seps[current() - 1])) then $seps[last()] else $seps[current() - 1]"/>
      </xsl:if>
      <xsl:apply-templates select="$els[current()]" mode="#current"/>
    </xsl:for-each>
    <xsl:call-template name="fence">
      <xsl:with-param name="pos" select="'right'"/>
      <xsl:with-param name="val" select="(@close, ')')[1]"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="fence">
    <xsl:param name="pos" as="xs:string"/><!-- left|right -->
    <xsl:param name="val" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="not(normalize-space($val))">
        <xsl:value-of select="concat('\', $pos, '.')"/>
      </xsl:when>
      <xsl:when test="$val = ('[', ']', '(', ')')">
        <xsl:value-of select="concat('\', $pos, $val)"/>
      </xsl:when>
      <xsl:when test="$val = ('{', '}')">
        <xsl:value-of select="concat('\', $pos, '\', $val)"/>
      </xsl:when>
      <xsl:when test="$val eq '&#x2016;'">
        <xsl:value-of select="concat('\', $pos, '|', '\', $pos, '|')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('\', $pos, string-join(mml2tex:utf2tex($val, (), (), ancestor-or-self::*[1]), ''), '&#x20;')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mo/text()[    matches(., $parenthesis-regex) 
                                 and not($katex = 'yes')
                                 and ($always-use-left-right = 'yes'
                                 or  ancestor::*[2]//*/local-name() = ('mfrac', 
                                                                       'mover', 
                                                                       'mroot', 
                                                                       'msqrt', 
                                                                       'mtable', 
                                                                       'munder', 
                                                                       'munderover'))]" 
                mode="mathml2tex" priority="10"> 
    <xsl:call-template name="fence">
      <xsl:with-param name="pos" select="if(matches(., '[\[\({&#x2308;&#x230a;&#x2329;&#x27e8;&#x3009;]')) 
                                         then 'left' 
                                         else 'right'"/>
      <xsl:with-param name="val" select="."/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="text()[. = $mml2tex:function-names]" mode="mathml2tex" priority="10">
    <xsl:value-of select="concat('\', replace(normalize-space(.), '&#xa;+', ' '), '&#x20;')"/>
  </xsl:template>
  
  <xsl:template match="text()[$use-upgreek-map] 
                             [exists(   parent::mi[    @mathvariant eq 'normal' 
                                                   or (    empty(@mathvariant) 
                                                       and string-length(.) gt 1)]
                                                  [matches(normalize-space(.), $texregex-upgreek)]
                             |parent::mtext[matches(normalize-space(.), $texregex-upgreek)])]"
     mode="mathml2tex" priority="8">
    <xsl:variable name="text" select="replace(normalize-space(.), '&#xa;+', ' ')" as="xs:string"/>
    <xsl:variable name="utf2tex-upgreek" 
                  select="if(. = ' ') then '\ ' else if(matches($text, $texregex-upgreek)) 
                                                     then string-join(mml2tex:utf2tex($text, $texmap-upgreek, $texregex-upgreek, ..), '')
                                                     else $text" as="xs:string"/>
      <xsl:value-of select="$utf2tex-upgreek"/>
  </xsl:template>
  
  <xsl:template match="mn/text()
                      |mi/text()
                      |mo/text()
                      |ms/text()" mode="mathml2tex" priority="5">
    <xsl:variable name="text" select="replace(normalize-space(.), '&#xa;+', ' ')" as="xs:string"/>
    <xsl:variable name="utf2tex" select="string-join(mml2tex:utf2tex($text, (), (), ..), '')" as="xs:string"/>
    <xsl:value-of select="$utf2tex"/>
  </xsl:template>
  
  <xsl:template match="mtext/text()" mode="mathml2tex" priority="5">
    <xsl:variable name="text" select="replace(., '&#xa;+', ' ')" as="xs:string"/>
    <xsl:variable name="utf2tex" select="string-join(mml2tex:utf2tex($text, (), (), ..), '')" as="xs:string"/>
    <xsl:value-of select="$utf2tex"/>
  </xsl:template>
  
  <xsl:template match="text()[matches(., concat('^(', $whitespace-regex, ')*$'))]" mode="mathml2tex">
    <xsl:text>&#x20;</xsl:text>
  </xsl:template>
  
  <xsl:template match="text()" mode="mathml2tex">
    <xsl:message select="'[WARNING]: unprocessed or empty text node', ."/>
  </xsl:template>
  
  <!-- remove whitespace -->
  
  <xsl:template match="*[not(local-name() = ('mi', 'mo', 'mn', 'ms', 'mtext'))]/text()[not(normalize-space(.))]" mode="mathml2tex"/>

  <xsl:function name="mml2tex:text-atts" as="xs:string?">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:param name="target" as="xs:string"/>
    <xsl:variable name="fontweight" select="$elt/@fontweight" as="attribute(fontweight)?"/>
    <xsl:variable name="fontstyle" select="$elt/@fontstyle" as="attribute(fontstyle)?"/>
    <xsl:variable name="mathvariant" select="$elt/@mathvariant" as="attribute(mathvariant)?"/>
    <xsl:choose>
      <xsl:when test="$fontweight = 'bold' and $fontstyle = 'italic' and not(matches($mathvariant, 'bold|normal'))">
        <xsl:sequence select="concat('\', $target, 'bi', '{')"/>
      </xsl:when>
      <xsl:when test="$fontweight = 'bold' and not(matches($mathvariant, 'bold|normal'))">
        <xsl:sequence select="concat('\', $target, 'bf', '{')"/>
      </xsl:when>
      <xsl:when test="$fontstyle = 'italic' and not(matches($mathvariant, 'italic|normal'))">
        <xsl:sequence select="concat('\', $target, 'it', '{')"/>
      </xsl:when>
    </xsl:choose>
  </xsl:function>
  
  <xsl:variable name="style-map" as="element(mml2tex:styles)">
    <styles xmlns="http://transpect.io/mml2tex">
      <var mml="normal"                 tex="rm"        targets="math"/>
      <var mml="bold"                   tex="bf"        targets="math text"/>
      <var mml="italic"                 tex="it"        targets="math text"/>
      <var mml="bold-italic"            tex="boldsymbol" targets="math text"/>
      <var mml="fraktur"                tex="frak"      targets="math text"/>
      <var mml="bold-fraktur"           tex="mathfrak"  targets="math text"/>
      <var mml="script"                 tex="cal"       targets="math text"/>
      <var mml="bold-script"            tex="boldsymbol cal"    targets="math text"/>
      <var mml="sans-serif"             tex="boldsymbol sf"     targets="math text"/>
      <var mml="bold-sans-serif"        tex="boldsymbol sf"     targets="math text"/>
      <var mml="sans-serif-italic"      tex="boldsymbol it sf"  targets="math text"/>
      <var mml="sans-serif-bold-italic" tex="boldsymbol it sf"  targets="math text"/>
      <var mml="double-struck"          tex="bb"        targets="math"/>
      <var mml="monospace"              tex="tt"        targets="math text"/>
    </styles>
  </xsl:variable>
  
  <xsl:function name="mml2tex:style-to-tex" as="item()*">
    <xsl:param name="elt" as="element()"/>
    <xsl:variable name="mathvariant" select="$elt/@mathvariant" as="attribute(mathvariant)?"/>
    <xsl:variable name="fontstyle"   select="$elt/@fontstyle"   as="attribute(fontstyle)?"/>
    <xsl:variable name="fontweight"  select="$elt/@fontweight"  as="attribute(fontweight)?"/>
    <xsl:choose>
      <xsl:when test="matches($elt, concat('^[', $whitespace-regex, ']+$')) 
                      or ($elt[not(node())])">
        <xsl:apply-templates select="$elt/node()" mode="mathml2tex"/>
      </xsl:when>
      <xsl:when test="(($elt/self::mtext and not($mathvariant))
                        or ($elt/self::mi and $mathvariant eq 'normal'))
                      and matches($elt, $texregex-upgreek)">
        <xsl:apply-templates select="$elt/node()" mode="mathml2tex"/>
      </xsl:when>
      <xsl:when test="$elt/self::mtext 
                      and normalize-space(string-join(($mathvariant, $fontstyle, $fontweight), '')) 
                      and not($mathvariant = 'normal')
                      and not(matches($elt, $texregex-upgreek))">
        <xsl:sequence select="mml2tex:style-to-tex-insert($elt, $mathvariant, 'text')"/>
      </xsl:when>
      <xsl:when test="$elt/self::mtext">
        <xsl:text>\text{</xsl:text>
        <xsl:apply-templates select="$elt/node()" mode="mathml2tex"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="$elt/self::mi[. = $mml2tex:function-names][$mathvariant = 'normal']">
        <xsl:apply-templates select="$elt/node()" mode="mathml2tex"/>
      </xsl:when>
      <xsl:when test="($elt/self::mi or $elt/self::mn or $elt/self::ms or $elt/self::mo or $elt/self::mstyle) 
                      and normalize-space(string-join(($mathvariant, $fontstyle, $fontweight), '')) 
                      and not($elt/self::mi[not(@mathvariant or @mathvariant eq 'italic')] and string-length($elt) = 1)">
        <xsl:sequence select="mml2tex:style-to-tex-insert($elt, $mathvariant, 'math')"/>
      </xsl:when>
      <xsl:when test="$elt/self::mi[$mathvariant = ('normal') or not($mathvariant)]
                                   [string-length($elt) gt 1]
                                   [not(matches($elt, $mml2tex:functions-names-regex))]
                                   [not(matches($elt, concat('^', $texregex-upgreek, '$')))]">
        <xsl:sequence select="mml2tex:style-to-tex-insert($elt, 'normal', 'math')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$elt/node()" mode="mathml2tex"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="mml2tex:style-to-tex-insert" as="item()*">
    <xsl:param name="elt" as="element()"/>
    <xsl:param name="mathvariant" as="xs:string?"/>
    <xsl:param name="target" as="xs:string"/>
    <xsl:variable name="tex-instructions" as="xs:string*"
                  select="tokenize($style-map/mml2tex:var[@mml eq $mathvariant]/@tex, '\s')"/>
    <xsl:value-of select="string-join((mml2tex:text-atts($elt, $target),
                                       for $i in $tex-instructions
                                       return ('\', 
                                               if($i = ('bm', 'boldsymbol')) then () else $target, $i, '{')
                                       ), '')"/>
    <xsl:apply-templates select="$elt/node()" mode="mathml2tex"/>
    <xsl:value-of select="string-join((for $i in $tex-instructions 
                                       return '}', 
                                       if(mml2tex:text-atts($elt, $target)) then '}' else ()), 
                                       '')"/>
  </xsl:function>

  <xsl:template match="mglyph" mode="mathml2tex">
    <xsl:message>[WARNING]: mglyph (<xsl:copy-of select="."/>)</xsl:message>
    <xsl:if test="@alt">
      <xsl:value-of select="@alt"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="mn|mi|ms|mo|mtext|mstyle" mode="mathml2tex">
    <xsl:sequence select="mml2tex:style-to-tex(.)"/>
  </xsl:template>
  
  <xsl:template match="processing-instruction()[local-name() eq 'latex']" mode="mathml2tex">
    <xsl:value-of select="."/>
  </xsl:template>
    
  <xsl:function name="mml2tex:utf2tex" as="xs:string*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="texmap-override" as="element(xml2tex:char)*"/>
    <xsl:param name="texregex-override" as="xs:string?"/>
    <xsl:param name="context" as="element()?"/>
    
    <xsl:variable name="chars" as="xs:string*" 
                  select="for $char in string-to-codepoints($string) 
                          return codepoints-to-string($char)"/>
    <xsl:variable name="texregex" select="($texregex-override, $texregex)[1]" as="xs:string"/>
    <xsl:variable name="texmap" select="($texmap-override, $texmap)" as="element(xml2tex:char)*"/>
    <xsl:for-each select="$chars">
      <xsl:variable name="char" select="." as="xs:string"/>
      <xsl:analyze-string select="." regex="{$texregex}">
  
        <xsl:matching-substring>
          <xsl:variable name="pattern" select="functx:escape-for-regex(.)" as="xs:string"/>
          <xsl:variable name="is-text" select="$context/local-name() = 'mtext'" as="xs:boolean"/>
          <xsl:variable name="unmapped-char" as="element(xml2tex:char)?"
                        select="if($is-text)
                        then ($texmap[@character eq $char][@mode eq 'text'], $texmap[@character eq $char][not(@mode)],$texmap[@character eq $char][@mode])[1]
                                else $texmap[@character eq $char][@mode eq 'math' or not(@mode)][1]"/>
          <xsl:variable name="replacement" as="xs:string"
                        select="if(exists($unmapped-char)) 
                                then replace($unmapped-char/@string, '(\$|\\)', '\\$1')
                                else ."/>
          <xsl:variable name="insert-whitespace" select="if(matches($replacement, '[-+\(\)\[\]\{\},:;\.&quot;''\?!]$')) 
                                                         then ()
                                                         else '&#x20;'" as="xs:string?"/>
          <xsl:variable name="result" select="replace(., 
                                                      $pattern, 
                                                      if (not($is-text)) 
                                                      then concat($replacement, 
                                                                    $insert-whitespace) 
                                                      else $replacement
                                                      )" as="xs:string"/>
          <!--<xsl:if test="matches($replacement, 'ddot')">
              <xsl:message select=".,'-\-\-', $result"></xsl:message>
          </xsl:if>-->
          <xsl:value-of select="$result"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:value-of select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:for-each>
  </xsl:function>
  
  <xsl:function name="functx:escape-for-regex" as="xs:string">
    <xsl:param name="arg" as="xs:string?"/> 
    <xsl:sequence select="replace($arg,
                                  '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')"/>
  </xsl:function>
  
  <!-- called by html renderers-->
  
  <xsl:variable name="display-formula-local-names" as="xs:string+" select="('disp-formula', 'equation', 'dformula')"/>
  
  <xsl:template name="mml:katexify">
    <xsl:param name="wrapper" as="xs:string" select="if(local-name(..) = $display-formula-local-names) 
                                                     then 'div' else 'span'"/>
    <xsl:variable name="mml2tex-grouping" as="element(mml:math)">
      <xsl:apply-templates select="." mode="mml2tex-grouping"/>
    </xsl:variable>
<!--    <xsl:if test="matches(., '^\s*3\s*$')">
      <xsl:message select="'IIIIIIIIIIII ', ."/>
    </xsl:if>
    <xsl:if test="matches(., '^\s*3\s*$')">
      <xsl:message select="'GGGGGGGGGGGG ', $mml2tex-grouping"/>
    </xsl:if>-->
    <xsl:variable name="mml2tex-preprocess" as="element(mml:math)">
      <xsl:apply-templates select="$mml2tex-grouping" mode="mml2tex-preprocess"/>
    </xsl:variable>
    <!--<xsl:if test="matches(., '^\s*3\s*$')">
      <xsl:message select="'PPPPPPPPPPPPP ', $mml2tex-preprocess"/>
    </xsl:if>-->
    <xsl:element name="{$wrapper}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:attribute name="class" select="$katex-class"/>
<!--      <grouping>
        <xsl:sequence select="$mml2tex-grouping"/>
      </grouping>
      <preprocess>
        <xsl:sequence select="$mml2tex-preprocess"/>
      </preprocess>
      <xsl:text>&#xa;&#xa;&#xa;</xsl:text>-->
      <xsl:apply-templates select="$mml2tex-preprocess" mode="mathml2tex">
        <xsl:with-param name="katexify-context" as="element(*)?" select=".." tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>
  
</xsl:stylesheet>
