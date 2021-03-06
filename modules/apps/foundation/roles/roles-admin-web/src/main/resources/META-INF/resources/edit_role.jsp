<%--
/**
 * Copyright (c) 2000-present Liferay, Inc. All rights reserved.
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

<%@ include file="/init.jsp" %>

<%
String redirect = ParamUtil.getString(request, "redirect");

String backURL = ParamUtil.getString(request, "backURL", redirect);

long roleId = ParamUtil.getLong(request, "roleId");

Role role = RoleServiceUtil.fetchRole(roleId);

String roleName = null;

if (role != null) {
	roleName = role.getName();
}

int type = ParamUtil.getInteger(request, "type");
String subtype = BeanParamUtil.getString(role, request, "subtype");

portletDisplay.setShowBackIcon(true);
portletDisplay.setURLBack(backURL);

renderResponse.setTitle((role == null) ? LanguageUtil.get(request, "new-role") : role.getTitle(locale));
%>

<portlet:actionURL name="editRole" var="editRoleURL">
	<portlet:param name="mvcPath" value="/edit_role.jsp" />
	<portlet:param name="backURL" value="<%= backURL %>" />
</portlet:actionURL>

<liferay-util:include page="/edit_role_tabs.jsp" servletContext="<%= application %>" />

<c:if test="<%= role != null %>">
	<c:choose>
		<c:when test="<%= role.getType() == RoleConstants.TYPE_REGULAR %>">
			<liferay-ui:success key="roleCreated" message='<%= LanguageUtil.format(request, "x-was-created-successfully.-you-can-now-define-its-permissions-and-assign-users", roleName) %>' />
		</c:when>
		<c:otherwise>
			<liferay-ui:success key="roleCreated" message='<%= LanguageUtil.format(request, "x-was-created-successfully.-you-can-now-define-its-permissions", roleName) %>' />
		</c:otherwise>
	</c:choose>
</c:if>

<aui:form action="<%= editRoleURL %>" cssClass="container-fluid-1280" method="post" name="fm">
	<aui:input name="redirect" type="hidden" value="<%= currentURL %>" />
	<aui:input name="roleId" type="hidden" value="<%= roleId %>" />

	<liferay-ui:error exception="<%= DuplicateRoleException.class %>" message="please-enter-a-unique-name" />
	<liferay-ui:error exception="<%= RequiredRoleException.class %>" message="old-role-name-is-a-required-system-role" />

	<liferay-ui:error exception="<%= RoleNameException.class %>">
		<p>
			<liferay-ui:message arguments="<%= new String[] {RoleConstants.NAME_LABEL, RoleConstants.getNameGeneralRestrictions(locale, PropsValues.ROLES_NAME_ALLOW_NUMERIC), RoleConstants.NAME_RESERVED_WORDS} %>" key="the-x-cannot-be-x-or-a-reserved-word-such-as-x" />
		</p>

		<p>
			<liferay-ui:message arguments="<%= new String[] {RoleConstants.NAME_LABEL, RoleConstants.NAME_INVALID_CHARACTERS} %>" key="the-x-cannot-contain-the-following-invalid-characters-x" />
		</p>
	</liferay-ui:error>

	<aui:model-context bean="<%= role %>" model="<%= Role.class %>" />

	<aui:fieldset-group markupView="lexicon">
		<aui:fieldset>
			<c:choose>
				<c:when test="<%= (role == null) && (type == 0) %>">
					<aui:select name="type">
						<aui:option label="regular" value="<%= RoleConstants.TYPE_REGULAR %>" />
						<aui:option label="site" value="<%= RoleConstants.TYPE_SITE %>" />
						<aui:option label="organization" value="<%= RoleConstants.TYPE_ORGANIZATION %>" />
					</aui:select>
				</c:when>
				<c:when test="<%= role == null %>">
					<aui:input label="type" name="typeLabel" type="resource" value="<%= LanguageUtil.get(request, RoleConstants.getTypeLabel(type)) %>" />

					<aui:input name="type" type="hidden" value="<%= String.valueOf(type) %>" />
				</c:when>
				<c:otherwise>
					<aui:input label="type" name="typeLabel" type="resource" value="<%= LanguageUtil.get(request, role.getTypeLabel()) %>" />
				</c:otherwise>
			</c:choose>

			<aui:input autoFocus="<%= windowState.equals(WindowState.MAXIMIZED) %>" name="title">
				<c:if test="<%= (role == null) || !role.isSystem() %>">
					<aui:validator name="required" />
				</c:if>
			</aui:input>

			<aui:input name="description" />

			<c:if test="<%= role != null %>">

				<%
				String[] subtypes = null;

				if (role.getType() == RoleConstants.TYPE_ORGANIZATION) {
					subtypes = PropsValues.ROLES_ORGANIZATION_SUBTYPES;
				}
				else if (role.getType() == RoleConstants.TYPE_REGULAR) {
					subtypes = PropsValues.ROLES_REGULAR_SUBTYPES;
				}
				else if (role.getType() == RoleConstants.TYPE_SITE) {
					subtypes = PropsValues.ROLES_SITE_SUBTYPES;
				}
				else {
					subtypes = new String[0];
				}
				%>

				<c:if test="<%= subtypes.length > 0 %>">
					<aui:select name="subtype">
						<aui:option value="" />

						<%
						for (String curSubtype : subtypes) {
						%>

							<aui:option label="<%= curSubtype %>" selected="<%= subtype.equals(curSubtype) %>" />

						<%
						}
						%>

					</aui:select>
				</c:if>
			</c:if>

			<c:choose>
				<c:when test="<%= (role != null) && role.isSystem() %>">
					<aui:input name="name" type="hidden" value="<%= roleName %>" />
				</c:when>
				<c:otherwise>
					<aui:input autoFocus="<%= windowState.equals(WindowState.MAXIMIZED) %>" helpMessage="key-field-help" label="key" name="name" />
				</c:otherwise>
			</c:choose>

			<c:if test="<%= (role != null) && roleName.equals(RoleConstants.SITE_ADMINISTRATOR) %>">
				<aui:input helpMessage="allow-subsite-management-help" label="allow-subsite-management" name="manageSubgroups" type="toggle-switch" value="<%= ResourcePermissionLocalServiceUtil.hasResourcePermission(company.getCompanyId(), Group.class.getName(), ResourceConstants.SCOPE_GROUP_TEMPLATE, String.valueOf(GroupConstants.DEFAULT_PARENT_GROUP_ID), roleId, ActionKeys.MANAGE_SUBGROUPS) %>" />
			</c:if>

			<%
			ExpandoBridge roleExpandoBridge = ExpandoBridgeFactoryUtil.getExpandoBridge(company.getCompanyId(), Role.class.getName(), (role != null) ? role.getRoleId() : 0);

			Map<String, Serializable> roleCustomAttributes = roleExpandoBridge.getAttributes();
			%>

			<c:if test="<%= roleCustomAttributes.size() > 0 %>">
				<aui:fieldset-group markupView="lexicon">
					<aui:fieldset>
						<liferay-expando:custom-attribute-list
							className="<%= Role.class.getName() %>"
							classPK="<%= (role != null) ? role.getRoleId() : 0 %>"
							editable="<%= true %>"
							label="<%= true %>"
						/>
					</aui:fieldset>
				</aui:fieldset-group>
			</c:if>

			<aui:button-row>
				<aui:button cssClass="btn-lg" type="submit" />

				<aui:button cssClass="btn-lg" href="<%= redirect %>" type="cancel" />
			</aui:button-row>
		</aui:fieldset>
	</aui:fieldset-group>
</aui:form>

<c:if test="<%= role == null %>">
	<aui:script sandbox="<%= true %>">
		var form = $(document.<portlet:namespace />fm);

		var nameInput = form.fm('name');
		var titleInput = form.fm('title');

		var onTitleInput = _.debounce(
			function(event) {
				nameInput.val(titleInput.val());
			},
			200
		);

		titleInput.on('input', onTitleInput);
	</aui:script>
</c:if>