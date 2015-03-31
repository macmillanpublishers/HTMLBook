<!DOCTYPE xsl:stylesheet [
  <!ENTITY blocksiblingxpath "((preceding-sibling::*[local-name() = 'address' or 
			                             local-name() = 'aside' or 
						     local-name() = 'audio' or 
						     local-name() = 'blockquote' or
			                             local-name() = 'canvas' or 
						     local-name() = 'details' or 
						     local-name() = 'div' or 
						     local-name() = 'dl' or
						     local-name() = 'embed' or 
						     local-name() = 'fieldset' or 
						     local-name() = 'figure' or 
						     local-name() = 'hr' or
						     local-name() = 'iframe' or 
						     local-name() = 'map' or 
						     local-name() = 'math' or 
						     local-name() = 'menu' or
						     local-name() = 'object' or 
						     local-name() = 'ol' or 
						     local-name() = 'p' or 
						     local-name() = 'pre' or
						     local-name() = 'svg' or 
						     local-name() = 'table' or 
						     local-name() = 'ul' or 
						     local-name() = 'video']) or
		               (following-sibling::*[local-name() = 'address' or 
			                             local-name() = 'aside' or 
						     local-name() = 'audio' or 
						     local-name() = 'blockquote' or
			                             local-name() = 'canvas' or 
						     local-name() = 'details' or 
						     local-name() = 'div' or 
						     local-name() = 'dl' or
						     local-name() = 'embed' or 
						     local-name() = 'fieldset' or 
						     local-name() = 'figure' or 
						     local-name() = 'hr' or
						     local-name() = 'iframe' or 
						     local-name() = 'map' or 
						     local-name() = 'math' or 
						     local-name() = 'menu' or
						     local-name() = 'object' or 
						     local-name() = 'ol' or 
						     local-name() = 'p' or 
						     local-name() = 'pre' or
						     local-name() = 'svg' or 
						     local-name() = 'table' or 
						     local-name() = 'ul' or 
						     local-name() = 'video']))">
]>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:exsl="http://exslt.org/common"
		xmlns:h="http://www.w3.org/1999/xhtml"
		xmlns:mml="http://www.w3.org/1998/Math/MathML"
		xmlns:svg="http://www.w3.org/2000/svg"
		xmlns="http://www.w3.org/1999/xhtml"
		extension-element-prefixes="exsl"
		exclude-result-prefixes="exsl h">

<!-- Template for id decoration on elements that need it for TOC and/or index generation. 
     Should be at a lower import level than tocgen.xsl and indexgen.xsl, so that those
     templates can override id-generation templates to add additional functionality, if needed -->

  <xsl:output method="xml"
              encoding="UTF-8"/>
  <xsl:preserve-space elements="*"/>

  <xsl:key name="footnote-nodes-by-id" match="h:span[@data-type='footnote']" use="@id"/>

  <!-- Elements that require ids: 
       * All <sections>
       * <div data-type="part">
       * All <a data-type="indexterm"> tags
    -->
  <!-- WARNING: If you need additional handling for these elements for other functionality,
       and you override this template elsewhere, make sure you add in id-decoration functionality -->
  <xsl:template match="h:section|h:div[contains(@data-type, 'part')]|h:aside|h:a[contains(@data-type, 'indexterm')]">
    <xsl:param name="process.footnotes" select="$process.footnotes"/>
    <xsl:param name="html4.structural.elements" select="$html4.structural.elements"/>
    <xsl:variable name="output-element-name">
      <xsl:call-template name="html.output.element">
	<xsl:with-param name="html4.structural.elements" select="$html4.structural.elements"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
      <xsl:apply-templates select="." mode="pdf-bookmark"/>
      <xsl:choose>
	<!-- If output element name matches local name (i.e., HTML4 fallback elements disabled), copy element as is and process descendant content -->
	<!-- ToDo: Refactor duplicate code in when/otherwise; perhaps do an apply-templates select="." with a process-section mode -->
	<xsl:when test="$output-element-name = local-name()">
	  <xsl:attribute name="id">
	    <xsl:call-template name="object.id"/>
	  </xsl:attribute>
	  <xsl:apply-templates/>
	  <xsl:if test="$process.footnotes = 1">
	    <xsl:call-template name="generate-footnotes"/>
	  </xsl:if>
	</xsl:when>
	<!-- If output element name does not match local name (i.e., HTML4 fallback elements enabled), copy element, but add an HTML4
	     fallback child wrapper to include descendant content -->
	<xsl:otherwise>
	  <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
	    <!-- Put a class on it with the proper semantic name -->
	    <xsl:attribute name="class">
	      <xsl:call-template name="semantic-name"/>
	    </xsl:attribute>
	    <xsl:attribute name="id">
	      <xsl:call-template name="object.id"/>
	    </xsl:attribute>
	    <xsl:apply-templates/>
	    <xsl:if test="$process.footnotes = 1">
	      <xsl:call-template name="generate-footnotes"/>
	    </xsl:if>
	  </xsl:element>
	</xsl:otherwise>
      </xsl:choose>      
    </xsl:copy>
  </xsl:template>

  <!-- Special handling for indexterm text nodes when there are no sibling text or element nodes -->
  <xsl:template match="h:a[@data-type='indexterm']/text()[not(preceding-sibling::node()) and not(following-sibling::node())]">
    <xsl:variable name="whitespace-only-in-indexterm">
      <xsl:call-template name="whitespace-only-in-text">
	<xsl:with-param name="text.content" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <!-- Only copy over text when it's not whitespace-only -->
    <!-- In other words, strip out whitespace-only text nodes in indexterms -->
    <xsl:if test="$whitespace-only-in-indexterm != 1">
     <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="h:section[@data-type]/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]|
		       h:section[@data-type]/h:header/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]|
		       h:div[@data-type = 'part' or @data-type = 'example' or @data-type = 'equation']/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]|
		       h:div[@data-type = 'part']/h:header/*[self::h:h1 or self::h:h2 or self::h:h3 or self::h:h4 or self::h:h5 or self::h:h6]">
    <xsl:param name="autogenerate.labels" select="$autogenerate.labels"/>
    <xsl:apply-templates select="." mode="process-heading">
      <xsl:with-param name="autogenerate.labels" select="$autogenerate.labels"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Custom handling for tables that have footnotes -->
  <xsl:template match="h:table[descendant::h:span[@data-type='footnote']]">
    <xsl:param name="process.footnotes" select="$process.footnotes"/>
    <xsl:variable name="number-of-table-columns">
      <xsl:apply-templates select="." mode="number.of.table.columns"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <!-- Put table footnotes in a tfoot -->
      <tfoot class="footnotes">
	<tr>
	  <td colspan="{$number-of-table-columns}">
	    <xsl:for-each select="descendant::h:span[@data-type='footnote']">
	      <xsl:apply-templates select="." mode="generate.footnote"/>
	    </xsl:for-each>
	  </td>
	</tr>
      </tfoot>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="h:figure">
    <xsl:param name="html4.structural.elements" select="$html4.structural.elements"/>
    <xsl:param name="figure.border.div" select="$figure.border.div"/>
    <xsl:variable name="output-element-name">
      <xsl:call-template name="html.output.element">
	<xsl:with-param name="html4.structural.elements" select="$html4.structural.elements"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
      <xsl:choose>
	<!-- If output element name matches local name (i.e., HTML4 fallback elements disabled), copy element as is and process descendant content -->
	<xsl:when test="$output-element-name = local-name()">
	  <xsl:apply-templates select="@id"/>
	  <xsl:call-template name="process-figure-contents">
	    <xsl:with-param name="figure.border.div" select="$figure.border.div"/>
	  </xsl:call-template>
	</xsl:when>
	<!-- If output element name does not match local name (i.e., HTML4 fallback elements enabled), copy element, but add an HTML4
	     fallback child wrapper to include descendant content -->
	<xsl:otherwise>
	  <xsl:element name="{$output-element-name}" namespace="http://www.w3.org/1999/xhtml">
	    <xsl:apply-templates select="@id"/>
	    <xsl:attribute name="class">
	      <xsl:call-template name="semantic-name"/>
	    </xsl:attribute>
	    <xsl:call-template name="process-figure-contents">
	      <xsl:with-param name="figure.border.div" select="$figure.border.div"/>
	    </xsl:call-template>
	  </xsl:element>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="process-figure-contents">
    <xsl:param name="node" select="."/>
    <xsl:param name="figure.border.div" select="$figure.border.div"/>
    <!-- If the parameter $figure.border.div is enabled, and there is a figure caption, add a child div and put everything but the caption in it -->
    <!-- Switch to the appropriate context node -->
    <xsl:for-each select="$node[1]">
      <xsl:choose>
	<xsl:when test="$figure.border.div = 1 and h:figcaption[text()]">
	  <!-- figcaption must be first or last; handle accordingly -->
	  <xsl:choose>
	    <!-- Only do border box when you've got a nonempty fig caption -->
	    <xsl:when test="*[1][self::h:figcaption]">
	      <xsl:apply-templates select="h:figcaption"/>
	      <div class="border-box">
		<xsl:apply-templates select="*[not(self::h:figcaption)]"/>
	      </div>
	    </xsl:when>
	    <xsl:when test="*[last()][self::h:figcaption]">
	      <div class="border-box">
		<xsl:apply-templates select="*[not(self::h:figcaption)]"/>
	      </div>
	      <xsl:apply-templates select="h:figcaption"/>
	    </xsl:when>
	    <xsl:otherwise>
	      <!-- Uh oh, <figcaption> in an invalid location (not at beginning or end of <figure>) -->
	      <xsl:call-template name="log-message">
		<xsl:with-param name="type" select="'WARNING'"/>
		<xsl:with-param name="message">
		  <xsl:text>Warning: figcaption for figure </xsl:text>
		  <xsl:value-of select="@id"/> 
		  <xsl:text>not at beginning or end of figure. Unable to add border box</xsl:text>
		</xsl:with-param>
	      </xsl:call-template>
	      <xsl:apply-templates/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="h:caption">
    <xsl:apply-templates select="." mode="process-heading">
      <xsl:with-param name="labeled-element-semantic-name" select="'table'"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="h:figcaption">
    <xsl:param name="html4.structural.elements" select="$html4.structural.elements"/>
    <xsl:apply-templates select="." mode="process-heading">
      <xsl:with-param name="labeled-element-semantic-name" select="'figure'"/>
      <xsl:with-param name="output-element-name">
	<xsl:call-template name="html.output.element">
	  <xsl:with-param name="html4.structural.elements" select="$html4.structural.elements"/>
	</xsl:call-template>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Admonition handling -->
  <xsl:template match="h:div[@data-type='note' or 
		             @data-type='tip' or 
			     @data-type='warning' or
			     @data-type='caution' or
			     @data-type='important']">
    <xsl:param name="add.title.heading.for.admonitions" select="$add.title.heading.for.admonitions"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!-- Add admonition heading title if $add.title.heading.for.admonitions is enabled AND there is not a heading first child already -->
      <xsl:if test="($add.title.heading.for.admonitions = 1) and
		    not(*[1][self::h:h1|self::h:h2|self::h:h3|self::h:h4|self::h:h5|self::h:h6])">
	<h6>
	  <!-- For title, use proper admonition title gentext, based on localization -->
	  <xsl:variable name="admon-semantic-name">
	    <xsl:call-template name="semantic-name">
	      <xsl:with-param name="node" select="."/>
	    </xsl:call-template>
	  </xsl:variable>
	  <xsl:call-template name="get-localization-value">
	    <xsl:with-param name="gentext-key" select="$admon-semantic-name"/>
	  </xsl:call-template>
	</h6>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- Footnote handling -->
  <xsl:template match="h:span[@data-type='footnote']">
    <xsl:param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
    <xsl:param name="process.footnotes" select="$process.footnotes"/>
    <xsl:choose>
      <xsl:when test="($process.footnotes = 1) or ancestor::h:table">
	<xsl:apply-templates select="." mode="footnote.marker">
	  <xsl:with-param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
	</xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy>
	  <xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:span[@data-type='footnote']" mode="footnote.marker" name="footnote-marker">
    <xsl:param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
    <sup>
    <a data-type="noteref">
      <xsl:attribute name="id">
	<xsl:call-template name="object.id"/>
	<xsl:text>-marker</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="href">
	<xsl:call-template name="href.target"/>
      </xsl:attribute>
	<!-- Use numbers for footnotes -->
	<!-- ToDo: Parameterize for numeration type and/or symbols? -->
	<xsl:apply-templates select="." mode="footnote.number">
	  <xsl:with-param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
	</xsl:apply-templates>
    </a>
    </sup>
  </xsl:template>

  <!-- Handling for footnoterefs a la DocBook (cross-references to an existing footnote) -->
  <xsl:template match="h:a[@data-type='footnoteref']">
    <xsl:param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
    <xsl:param name="process.footnotes" select="$process.footnotes"/>
    <xsl:variable name="referenced-footnote-id">
      <!-- Assuming that href is in the format href="#footnote_id" -->
      <xsl:value-of select="substring-after(@href, '#')"/>
    </xsl:variable>
    <xsl:variable name="referenced-footnote" select="key('footnote-nodes-by-id', $referenced-footnote-id)"/>

    <xsl:choose>
      <xsl:when test="count($referenced-footnote) &gt; 0">
	<!-- Switch the context node to that of the referenced footnote -->
	<xsl:for-each select="$referenced-footnote[1]">
	  <xsl:variable name="footnoteref.number">
	    <!-- Use numbers for footnotes -->
	    <!-- ToDo: Parameterize for numeration type and/or symbols? -->
	    <xsl:apply-templates select="." mode="footnote.number">
	      <xsl:with-param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
	    </xsl:apply-templates>
	  </xsl:variable>
	  <xsl:choose>
	    <xsl:when test="($process.footnotes = 1) or ancestor::h:table">
	      <!-- Same general handling as regular footnote markers, except footnoterefs don't get ids -->
	      <sup>
		<a data-type="noteref">
		  <xsl:attribute name="href">
		    <xsl:call-template name="href.target"/>
		  </xsl:attribute>
		  <xsl:value-of select="$footnoteref.number"/>
		</a>
	      </sup>
	    </xsl:when>
	    <xsl:otherwise>
	      <!-- If footnotes are not being processed, just output a sup with correct marker number -->
	      <sup class="footnoteref">
		<xsl:value-of select="$footnoteref.number"/>
	      </sup>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
	<!-- Uh oh, couldn't find the corresponding footnote for the footnoteref -->
	<xsl:call-template name="log-message">
	  <xsl:with-param name="type" select="'WARNING'"/>
	  <xsl:with-param name="message">
	    <xsl:text>Error: Could not find footnote referenced by footnoteref link </xsl:text>
	    <xsl:value-of select="@href"/>
	    <xsl:text>. Footnote marker will not be generated.</xsl:text>
	  </xsl:with-param>
	</xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Template for numbering footnotes -->
  <xsl:template match="h:span[@data-type='footnote']" mode="footnote.number">
    <xsl:param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
    <xsl:choose>
      <xsl:when test="ancestor::h:table">
	<!-- Count footnotes from this table -->
	<xsl:number count="h:span[@data-type='footnote'][ancestor::h:table]" from="h:table" level="any" format="{$table.footnote.numeration.format}"/>
      </xsl:when>
      <xsl:when test="$footnote.reset.numbering.at.chapter.level = 1">
	<!-- Count non-table footnotes only from most recent chapter-level element -->
	<xsl:number count="h:span[@data-type='footnote'][not(ancestor::h:table)]" 
		    level="any" format="{$footnote.numeration.format}"
		    from="h:section[parent::h:body or 
			  parent::h:div[@data-type='part'] or
			  not(ancestor::h:section)]|
			  h:div[@data-type='part']"/>
      </xsl:when>
      <xsl:otherwise>
	<!-- Count non-table footnotes from beginning of content -->
	<xsl:number count="h:span[@data-type='footnote'][not(ancestor::h:table)]" level="any" format="{$footnote.numeration.format}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="generate-footnotes">
    <!-- For standard, one-chunk output, we put all the footnotes at the end of the last chapter or appendix -->
    <!-- (Note that if there are no chapters or appendixes in the book, footnotes will not be generated properly. This can be changed
	 if we determine that there are other main-book-div types that can hold footnotes at the end of a book) --> 
    <xsl:if test="self::h:section[@data-type='chapter' or @data-type='appendix'] and not(following::h:section[@data-type='chapter' or @data-type='appendix']) and count(//h:span[@data-type='footnote'][not(ancestor::h:table)]) > 0">
      <!-- Footnotes should be put in an aside by default, but we call html.output.element to see if <aside> should be remapped to something else -->
      <!-- Kludge-y way to get an aside element -->
      <xsl:variable name="aside-element">
	<aside/>
      </xsl:variable>
      <xsl:variable name="footnote-element-name">
	<xsl:call-template name="html.output.element">
	  <xsl:with-param name="node" select="exsl:node-set($aside-element)/*[1]"/>
	</xsl:call-template>
      </xsl:variable>
      <xsl:element name="{$footnote-element-name}" namespace="http://www.w3.org/1999/xhtml">
	<xsl:attribute name="data-type">footnotes</xsl:attribute>
	<xsl:apply-templates select="//h:span[@data-type='footnote'][not(ancestor::h:table)]" mode="generate.footnote"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template match="h:span[@data-type='footnote']" mode="generate.footnote">
    <xsl:param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
    <p data-type="footnote">
      <xsl:attribute name="id">
	<xsl:call-template name="object.id"/>
      </xsl:attribute>
      <sup>
      <a>
	<xsl:attribute name="href">
	  <xsl:call-template name="href.target"/>
	  <xsl:text>-marker</xsl:text>
	</xsl:attribute>
	  <!-- Use numbers for footnotes -->
	  <!-- ToDo: Parameterize for numeration type and/or symbols? -->
	  <xsl:apply-templates select="." mode="footnote.number">
	    <xsl:with-param name="footnote.reset.numbering.at.chapter.level" select="$footnote.reset.numbering.at.chapter.level"/>
	  </xsl:apply-templates>
      </a>
      </sup>
      <xsl:text> </xsl:text>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="h:iframe|h:script">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <!-- Don't want to allow self-closing <iframe/> or <script/> tags, as many browsers don't like those -->
      <xsl:if test="not(node())">
	<xsl:text> </xsl:text>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <!-- Comment-specific handling -->

  <!-- Elements tagged with data-type="comment" -->
  <xsl:template match="*[@data-type='comment']">
    <xsl:param name="show-comments" select="$show-comments"/>
    <!-- Only show comments if show-comments is turned on -->
    <xsl:if test="$show-comments = 1">
      <xsl:copy>
	<xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <!-- XML comments in inline context -->
  <xsl:template match="comment()">
    <xsl:param name="show-comments" select="$show-comments"/>
    <!-- Only show comments if show-comments is turned on -->
    <xsl:choose>
      <xsl:when test="$show-comments = 1">
	<xsl:choose>
	  <!-- Still drop comments in MML or SVG -->
	  <xsl:when test="ancestor::math or ancestor::mml:math or ancestor::svg or ancestor::svg:svg"/>
	  <xsl:when test="parent::h:body or
			  parent::h:section or 
			  parent::h:div[@data-type='part'] or 
			  (parent::h:aside and &blocksiblingxpath;) or
			  parent::h:audio or
			  (parent::h:blockquote and &blocksiblingxpath;) or
			  parent::h:canvas or
			  (parent::h:details and &blocksiblingxpath;) or
			  (parent::h:div and &blocksiblingxpath;) or
			  parent::h:dl or
			  (parent::h:dd and &blocksiblingxpath;) or
			  parent::h:embed or
			  (parent::h:fieldset and &blocksiblingxpath;) or
			  parent::h:figure or
			  parent::h:form or
			  parent::h:iframe or
			  parent::h:map or
			  (parent::h:menu and &blocksiblingxpath;) or
			  (parent::h:object and &blocksiblingxpath;) or
			  parent::h:ol or
			  parent::h:table or
			  parent::h:ul or
			  parent::h:video">
	    <!-- Comment is in a block context  -->
	    <p class="comment">
	      <xsl:value-of select="."/>
	    </p>
	  </xsl:when>
	  <xsl:otherwise>
	    <!-- Comment is an inline comment -->
	    <span class="comment">
	      <xsl:value-of select="."/>
	    </span>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy>
	  <xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
