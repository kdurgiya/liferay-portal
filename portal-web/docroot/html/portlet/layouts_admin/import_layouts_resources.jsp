<%--
/**
 * Copyright (c) 2000-2013 Liferay, Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 */
--%>

<%@ include file="/html/portlet/layouts_admin/init.jsp" %>

<%
String redirect = ParamUtil.getString(request, "redirect");

long groupId = ParamUtil.getLong(request, "groupId");

Group group = null;

if (groupId > 0) {
	group = GroupLocalServiceUtil.getGroup(groupId);
}
else {
	group = (Group)request.getAttribute(WebKeys.GROUP);
}

Group liveGroup = group;

if (group.isStagingGroup()) {
	liveGroup = group.getLiveGroup();
}

boolean privateLayout = ParamUtil.getBoolean(request, "privateLayout");

FileEntry fileEntry = ExportImportUtil.getTempFileEntry(groupId, themeDisplay.getUserId());

ManifestSummary manifestSummary = com.liferay.portal.kernel.lar.ExportImportUtil.getManifestSummary(user.getUserId(), themeDisplay.getSiteGroupId(), new HashMap<String, String[]>(), fileEntry);
%>

<liferay-ui:error exception="<%= LARFileException.class %>" message="please-specify-a-lar-file-to-import" />

<liferay-ui:error exception="<%= LARFileSizeException.class %>">
	<liferay-ui:message arguments="<%= PrefsPropsUtil.getLong(PropsKeys.UPLOAD_SERVLET_REQUEST_IMPL_MAX_SIZE) / 1024 %>" key="please-enter-a-file-with-a-valid-file-size-no-larger-than-x" />
</liferay-ui:error>

<liferay-ui:error exception="<%= LARTypeException.class %>">

	<%
	LARTypeException lpe = (LARTypeException)errorException;
	%>

	<liferay-ui:message arguments="<%= lpe.getMessage() %>" key="please-import-a-lar-file-of-the-correct-type-x-is-not-valid" />
</liferay-ui:error>

<liferay-ui:error exception="<%= LayoutImportException.class %>" message="an-unexpected-error-occurred-while-importing-your-file" />

<liferay-ui:error exception="<%= LayoutPrototypeException.class %>">

	<%
	LayoutPrototypeException lpe = (LayoutPrototypeException)errorException;
	%>

	<liferay-ui:message key="the-lar-file-could-not-be-imported-because-it-requires-page-templates-or-site-templates-that-could-not-be-found.-please-import-the-following-templates-manually" />

	<ul>

		<%
		List<Tuple> missingLayoutPrototypes = lpe.getMissingLayoutPrototypes();

		for (Tuple missingLayoutPrototype : missingLayoutPrototypes) {
			String layoutPrototypeClassName = (String)missingLayoutPrototype.getObject(0);
			String layoutPrototypeUuid = (String)missingLayoutPrototype.getObject(1);
			String layoutPrototypeName = (String)missingLayoutPrototype.getObject(2);
		%>

			<li>
				<%= ResourceActionsUtil.getModelResource(locale, layoutPrototypeClassName) %>: <strong><%= layoutPrototypeName %></strong> (<%= layoutPrototypeUuid %>)
			</li>

		<%
		}
		%>

	</ul>
</liferay-ui:error>

<liferay-ui:error exception="<%= LocaleException.class %>">

	<%
	LocaleException le = (LocaleException)errorException;
	%>

	<liferay-ui:message arguments="<%= new String[] {StringUtil.merge(le.getSourceAvailableLocales(), StringPool.COMMA_AND_SPACE), StringUtil.merge(le.getTargetAvailableLocales(), StringPool.COMMA_AND_SPACE)} %>" key="the-available-languages-in-the-lar-file-x-do-not-match-the-portal's-available-languages-x" />
</liferay-ui:error>

<liferay-ui:error exception="<%= RecordSetDuplicateRecordSetKeyException.class %>">

	<%
	RecordSetDuplicateRecordSetKeyException rsdrske = (RecordSetDuplicateRecordSetKeyException)errorException;
	%>

	<liferay-ui:message arguments="<%= rsdrske.getRecordSetKey() %>" key="dynamic-data-list-record-set-with-record-set-key-x-already-exists" />
</liferay-ui:error>

<liferay-ui:error exception="<%= StructureDuplicateStructureKeyException.class %>">

	<%
	StructureDuplicateStructureKeyException sdske = (StructureDuplicateStructureKeyException)errorException;
	%>

	<liferay-ui:message arguments="<%= sdske.getStructureKey() %>" key="dynamic-data-mapping-structure-with-structure-key-x-already-exists" />
</liferay-ui:error>

<portlet:actionURL var="importPagesURL">
	<portlet:param name="struts_action" value="/layouts_admin/import_layouts" />
	<portlet:param name="<%= Constants.CMD %>" value="<%= Constants.IMPORT %>" />
	<portlet:param name="groupId" value="<%= String.valueOf(groupId) %>" />
	<portlet:param name="privateLayout" value="<%= String.valueOf(privateLayout) %>" />
</portlet:actionURL>

<aui:form action="<%= importPagesURL %>" cssClass="lfr-export-dialog" method="post" name="fm1">
	<div class="export-dialog-tree">
		<aui:fieldset cssClass="options-group" label="file">
			<dl class="import-file-details">
				<dt>
					<liferay-ui:message key="name" />
				</dt>
				<dd>
					<%= fileEntry.getTitle() %>
				</dd>
				<dt>
					<liferay-ui:message key="exported" />
				</dt>
				<dd>

					<%
					Date exportDate = manifestSummary.getExportDate();
					%>

					<span onmouseover="Liferay.Portal.ToolTip.show(this, '<%= dateFormatDateTime.format(exportDate) %>')">
						<liferay-ui:message arguments="<%= LanguageUtil.getTimeDescription(pageContext, System.currentTimeMillis() - exportDate.getTime(), true) %>" key="x-ago" />
					</span>
				</dd>
				<dt>
					<liferay-ui:message key="author" />
				</dt>
				<dd>
					<%= fileEntry.getUserName() %>
				</dd>
				<dt>
					<liferay-ui:message key="size" />
				</dt>
				<dd>
					<%= fileEntry.getSize() / 1024 %>k
				</dd>
			</dl>
		</aui:fieldset>

		<c:if test="<%= !group.isLayoutPrototype() %>">
			<aui:fieldset cssClass="options-group" label="pages">
				<div class="selected-labels" id="<portlet:namespace />selectedPages"></div>

				<aui:a cssClass="modify-link" href="javascript:;" id="pagesLink" label="change" method="get" />

				<div class="hide" id="<portlet:namespace />pages">
					<aui:fieldset cssClass="portlet-data-section" label="pages">
						<aui:input helpMessage="delete-missing-layouts-help" label="delete-missing-layouts" name="<%= PortletDataHandlerKeys.DELETE_MISSING_LAYOUTS %>" type="checkbox" value="<%= false %>" />

						<aui:input label="site-pages-settings" name="<%= PortletDataHandlerKeys.LAYOUT_SET_SETTINGS %>" type="checkbox" value="<%= true %>" />

						<aui:input helpMessage="export-import-theme-help" label="theme" name="<%= PortletDataHandlerKeys.THEME %>" type="checkbox" value="<%= true %>" />

						<aui:input helpMessage="export-import-theme-settings-help" label="theme-settings" name="<%= PortletDataHandlerKeys.THEME_REFERENCE %>" type="checkbox" value="<%= true %>" />

						<aui:input label="logo" name="<%= PortletDataHandlerKeys.LOGO %>" type="checkbox" value="<%= true %>" />
					</aui:fieldset>
				</div>
			</aui:fieldset>
		</c:if>

		<aui:fieldset cssClass="options-group" label="application-configuration">
			<ul class="lfr-tree unstyled">
				<li class="tree-item">
					<aui:input checked="<%= true %>" helpMessage="all-applications-import-help" id="allApplications" label="all-applications" name="<%= PortletDataHandlerKeys.PORTLET_SETUP %>" type="radio" value="<%= true %>" />

					<ul id="<portlet:namespace />showGlobalConfiguration">
						<li class="tree-item">
							<div class="selected-labels" id="<portlet:namespace />selectedGlobalConfiguration"></div>

							<aui:a cssClass="modify-link" href="javascript:;" id="globalConfigurationLink" label="change" method="get" />
						</li>
					</ul>

					<aui:script>
						Liferay.Util.toggleBoxes('<portlet:namespace /><%= PortletDataHandlerKeys.PORTLET_SETUP %>Checkbox', '<portlet:namespace />showGlobalConfiguration');
					</aui:script>

					<div class="hide" id="<portlet:namespace />globalConfiguration">
						<aui:fieldset cssClass="portlet-data-section" label="all-applications">
							<aui:input label="archived-setups" name="<%= PortletDataHandlerKeys.PORTLET_ARCHIVED_SETUPS %>" type="checkbox" value="<%= true %>" />

							<aui:input helpMessage="import-user-preferences-help" label="user-preferences" name="<%= PortletDataHandlerKeys.PORTLET_USER_PREFERENCES %>" type="checkbox" value="<%= true %>" />
						</aui:fieldset>
					</div>

					<aui:input id="chooseApplications" label="choose-applications" name="<%= PortletDataHandlerKeys.PORTLET_SETUP %>" type="radio" value="<%= false %>" />

					<c:if test="<%= !group.isLayoutPrototype() %>">
						<ul class="hide" id="<portlet:namespace />selectApplications">

							<%
							List<Portlet> setupPortlets = manifestSummary.getSetupPortlets();

							for (Portlet portlet : setupPortlets) {
								PortletDataHandler portletDataHandler = portlet.getPortletDataHandlerInstance();
							%>

								 <li class="tree-item">
									<aui:input label="<%= PortalUtil.getPortletTitle(portlet, application, locale) %>" name="<%= PortletDataHandlerKeys.PORTLET_SETUP + StringPool.UNDERLINE + portlet.getPortletId() %>" type="checkbox" value="<%= portletDataHandler.isPublishToLiveByDefault() %>" />
								</li>

							<%
							}
							%>

						</ul>
					</c:if>
				</li>
			</ul>
		</aui:fieldset>

		<aui:fieldset cssClass="options-group" label="content">
			<ul class="lfr-tree unstyled">
				<li class="tree-item">
					<div class="selected-labels" id="<portlet:namespace />selectedGlobalContent"></div>
				</li>

				<aui:a cssClass="modify-link" href="javascript:;" id="globalContentLink" label="change" method="get" />

				<li class="tree-item">
					<aui:input checked="<%= true %>" helpMessage="all-content-import-help" id="allContent" label="all-content" name="<%= PortletDataHandlerKeys.PORTLET_DATA %>" type="radio" value="<%= true %>" />

					<div class="hide" id="<portlet:namespace />globalContent">
						<aui:fieldset cssClass="portlet-data-section" label="all-content">
							<aui:input label="delete-portlet-data-before-importing" name="<%= PortletDataHandlerKeys.DELETE_PORTLET_DATA %>" type="checkbox" />

							<ul id="<portlet:namespace />showDeleteContentWarning">
								<div class="alert alert-block">
									<liferay-ui:message key="delete-content-before-importing-warning" />

									<liferay-ui:message key="delete-content-before-importing-suggestion" />
								</div>
							</ul>

							<aui:input helpMessage="export-import-categories-help" label="categories" name="<%= PortletDataHandlerKeys.CATEGORIES %>" type="checkbox" value="<%= false %>" />
						</aui:fieldset>

						<aui:script>
							Liferay.Util.toggleBoxes('<portlet:namespace /><%= PortletDataHandlerKeys.DELETE_PORTLET_DATA %>Checkbox', '<portlet:namespace />showDeleteContentWarning');
						</aui:script>

						<aui:fieldset cssClass="portlet-data-section" label="update-data">
							<aui:input checked="<%= true %>" helpMessage="import-data-strategy-mirror-help" id="mirror" label="mirror" name="<%= PortletDataHandlerKeys.DATA_STRATEGY %>" type="radio" value="<%= PortletDataHandlerKeys.DATA_STRATEGY_MIRROR %>" />

							<aui:input helpMessage="import-data-strategy-mirror-with-overwriting-help" id="mirrorWithOverwriting" label="mirror-with-overwriting" name="<%= PortletDataHandlerKeys.DATA_STRATEGY %>" type="radio" value="<%= PortletDataHandlerKeys.DATA_STRATEGY_MIRROR_OVERWRITE %>" />

							<aui:input helpMessage="import-data-strategy-copy-as-new-help" id="copyAsNew" label="copy-as-new" name="<%= PortletDataHandlerKeys.DATA_STRATEGY %>" type="radio" value="<%= PortletDataHandlerKeys.DATA_STRATEGY_COPY_AS_NEW %>" />
						</aui:fieldset>

						<aui:fieldset cssClass="portlet-data-section" label="authorship-of-the-content">
							<aui:input checked="<%= true %>" helpMessage="use-the-original-author-help" id="currentUserId" label="use-the-original-author" name="<%= PortletDataHandlerKeys.USER_ID_STRATEGY %>" type="radio" value="<%= UserIdStrategy.CURRENT_USER_ID %>" />

							<aui:input helpMessage="use-the-current-user-as-author-help" id="alwaysCurrentUserId" label="use-the-current-user-as-author" name="<%= PortletDataHandlerKeys.USER_ID_STRATEGY %>" type="radio" value="<%= UserIdStrategy.ALWAYS_CURRENT_USER_ID %>" />
						</aui:fieldset>
					</div>

					<aui:input id="chooseContent" label="choose-content" name="<%= PortletDataHandlerKeys.PORTLET_DATA %>" type="radio" value="<%= false %>" />


					<ul class="hide" id="<portlet:namespace />selectContents">
						<aui:input name="<%= PortletDataHandlerKeys.PORTLET_DATA_CONTROL_DEFAULT %>" type="hidden" value="<%= true %>" />

						<aui:input name="<%= PortletDataHandlerKeys.PORTLET_DATA %>" type="hidden" value="<%= true %>" />

						<%
						Set<String> displayedControls = new HashSet<String>();

						List<Portlet> dataPortlets = manifestSummary.getDataPortlets();

						for (Portlet portlet : dataPortlets) {
							String portletTitle = PortalUtil.getPortletTitle(portlet, application, locale);

							PortletDataHandler portletDataHandler = portlet.getPortletDataHandlerInstance();

							long importModelCount = portletDataHandler.getExportModelCount(manifestSummary);
						%>

							<c:if test="<%= importModelCount != 0 %>">
								<li>
									<aui:input checked="<%= portletDataHandler.isPublishToLiveByDefault() %>" label='<%= portletTitle + (importModelCount > 0 ? " (" + importModelCount + ")" : StringPool.BLANK) %>' name="<%= PortletDataHandlerKeys.PORTLET_DATA + StringPool.UNDERLINE + portlet.getPortletId() %>" type="checkbox" />

									<%
									PortletDataHandlerControl[] importControls = portletDataHandler.getImportControls();
									PortletDataHandlerControl[] importMetadataControls = portletDataHandler.getImportMetadataControls();

									if (Validator.isNotNull(importControls) || Validator.isNotNull(importMetadataControls)) {
									%>

										<div class="hide" id="<portlet:namespace />content_<%= portlet.getPortletId() %>">
											<ul class="lfr-tree unstyled">
												<li class="tree-item">
													<aui:fieldset cssClass="portlet-type-data-section" label="<%= portletTitle %>">

														<%
														if (importControls != null) {
															request.setAttribute("render_controls.jsp-action", Constants.EXPORT);
															request.setAttribute("render_controls.jsp-controls", importControls);
															request.setAttribute("render_controls.jsp-manifestSummary", manifestSummary);
															request.setAttribute("render_controls.jsp-portletDisabled", !portletDataHandler.isPublishToLiveByDefault());
														%>

															<aui:field-wrapper label="content">
																<ul class="lfr-tree unstyled">
																	<liferay-util:include page="/html/portlet/layouts_admin/render_controls.jsp" />
																</ul>
															</aui:field-wrapper>

														<%
														}

														if (importMetadataControls != null) {
															for (PortletDataHandlerControl metadataControl : importMetadataControls) {
																if (!displayedControls.contains(metadataControl.getControlName())) {
																	displayedControls.add(metadataControl.getControlName());
																}
																else {
																	continue;
																}

																PortletDataHandlerBoolean control = (PortletDataHandlerBoolean)metadataControl;

																PortletDataHandlerControl[] childrenControls = control.getChildren();

																if ((childrenControls != null) && (childrenControls.length > 0)) {
																	request.setAttribute("render_controls.jsp-controls", childrenControls);
																%>

																<aui:field-wrapper label="content-metadata">
																	<ul class="lfr-tree unstyled">
																		<liferay-util:include page="/html/portlet/layouts_admin/render_controls.jsp" />
																	</ul>
																</aui:field-wrapper>

																<%
																}
															}
														}
														%>

													</aui:fieldset>
												</li>
											</ul>
										</div>

										<ul class="hide" id="<portlet:namespace />showChangeContent_<%= portlet.getPortletId() %>">
											<li>
												<div class="selected-labels" id="<portlet:namespace />selectedContent_<%= portlet.getPortletId() %>"></div>

												<%
												Map<String,Object> data = new HashMap<String,Object>();

												data.put("portletid", portlet.getPortletId());
												%>

												<aui:a cssClass="content-link modify-link" data="<%= data %>" href="javascript:;" label="change" method="get" />
											</li>
										</ul>

										<aui:script>
											Liferay.Util.toggleBoxes('<portlet:namespace /><%= PortletDataHandlerKeys.PORTLET_DATA + StringPool.UNDERLINE + portlet.getPortletId() %>Checkbox', '<portlet:namespace />showChangeContent<%= StringPool.UNDERLINE + portlet.getPortletId() %>');
										</aui:script>

									<%
									}
									%>

								</li>
							</c:if>

						<%
						}
						%>

					</ul>
				</li>
			</ul>
		</aui:fieldset>

		<aui:fieldset cssClass="options-group" label="permissions">
			<ul class="lfr-tree unstyled">
				<li class="tree-item">
					<aui:input label="permissions" name="<%= PortletDataHandlerKeys.PERMISSIONS %>" type="checkbox" />

					<ul id="<portlet:namespace />selectPermissions">
						<li class="tree-item">
							<aui:input label="permissions-assigned-to-roles" name="permissionsAssignedToRoles" type="checkbox" value="<%= true %>" />
						</li>
					</ul>

					<aui:script>
						Liferay.Util.toggleBoxes('<portlet:namespace /><%= PortletDataHandlerKeys.PERMISSIONS %>Checkbox', '<portlet:namespace />selectPermissions');
					</aui:script>
				</li>
			</ul>
		</aui:fieldset>
	</div>

	<aui:button-row>
		<aui:button type="submit" value="import" />
	</aui:button-row>
</aui:form>

<aui:script use="liferay-export-import">
	new Liferay.ExportImport(
		{
			alwaysCurrentUserIdNode: '#alwaysCurrentUserIdNode',
			archivedSetupsNode: '#<%= PortletDataHandlerKeys.PORTLET_ARCHIVED_SETUPS %>Checkbox',
			categoriesNode: '#<%= PortletDataHandlerKeys.CATEGORIES %>Checkbox',
			copyAsNewNode: '#copyAsNew',
			currentUserIdNode: '#currentUserId',
			deleteMissingLayoutsNode: '#<%= PortletDataHandlerKeys.DELETE_MISSING_LAYOUTS %>Checkbox',
			deletePortletDataNode: '#<%= PortletDataHandlerKeys.DELETE_PORTLET_DATA %>Checkbox',
			dialogTitle: '<%= UnicodeLanguageUtil.get(pageContext, "content-to-import") %>',
			form: document.<portlet:namespace />fm1,
			layoutSetSettingsNode: '#<%= PortletDataHandlerKeys.LAYOUT_SET_SETTINGS %>Checkbox',
			logoNode: '#<%= PortletDataHandlerKeys.LOGO %>Checkbox',
			mirrorNode: '#mirror',
			mirrorWithOverwritingNode: '#mirrorWithOverwriting',
			namespace: '<portlet:namespace />',
			themeNode: '#<%= PortletDataHandlerKeys.THEME %>Checkbox',
			themeReferenceNode: '#<%= PortletDataHandlerKeys.THEME_REFERENCE %>Checkbox',
			userPreferencesNode: '#<%= PortletDataHandlerKeys.PORTLET_USER_PREFERENCES %>Checkbox'
		}
	);
</aui:script>

<aui:script>
	Liferay.Util.toggleRadio('<portlet:namespace />chooseApplications', '<portlet:namespace />selectApplications', '');
	Liferay.Util.toggleRadio('<portlet:namespace />allApplications', '', ['<portlet:namespace />selectApplications']);

	Liferay.Util.toggleRadio('<portlet:namespace />chooseContent', '<portlet:namespace />selectContents', ['<portlet:namespace />showChangeGlobalContent']);
	Liferay.Util.toggleRadio('<portlet:namespace />allContent', '<portlet:namespace />showChangeGlobalContent', ['<portlet:namespace />selectContents']);
</aui:script>